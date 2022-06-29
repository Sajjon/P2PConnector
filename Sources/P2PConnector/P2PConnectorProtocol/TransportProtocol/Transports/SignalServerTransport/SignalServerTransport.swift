//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-28.
//

import Foundation

public actor SignalServerTransport: TransportProtocol {
    
    private let connectionID: ConnectionID
    private let encryption: EncryptionProtocol
    private let networking: NetworkingProtocol
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder
    
    public init(
        connectionID: ConnectionID,
        encryption: EncryptionProtocol,
        networking: NetworkingProtocol,
        jsonEncoder: JSONEncoder = .init(),
        jsonDecoder: JSONDecoder = .init()
    ) {
        self.connectionID = connectionID
        self.encryption = encryption
        self.networking = networking
        self.jsonEncoder = jsonEncoder
        self.jsonDecoder = jsonDecoder
    }
    
}

// MARK: - Public

// MARK: - TransportProtocol (Public)
public extension SignalServerTransport {
    
    func initialize() async throws {
        await networking.connect()
        let subscribe = Subscribe(connectionID: connectionID)
        try await transportPlaintext(payload: subscribe, type: .subscribe)
    }
  
    func transport(offer: Offer) async throws {
        try await transport(
            encrypting: offer,
            type: .offer
        )
    }
    
    func transport(iceCandidates: [ICECandidate]) async throws {
        for iceCandidate in iceCandidates {
            try await transport(
                encrypting: iceCandidate,
                type: .iceCandidate
            )
        }
    }
    
    func fetchAnswer() async throws -> Answer {
        try await fetchPayload(type: .answer)
    }
    
    /// N.B. This REQUIRES that browserExtension batches ICECandidates and
    /// are aware of how many candidates it batched during some duration when
    /// it transports the first candidate to the mobile client.
    func fetchICECandidates() async throws -> [ICECandidate] {
       
        var iceCandidates: [ICECandidate] = []
        
        let firstRemoteICECandidate = try await fetchPayload(
            type: .iceCandidate,
            as: IndexICECandidate.self
        )
        
        iceCandidates.append(firstRemoteICECandidate.iceCandidate)
       
        var remainingICECandidates = firstRemoteICECandidate.totalNumberOfCandidates - 1 // minus one because we just got the first...
       
        while remainingICECandidates > 0 {
            let remoteICECandidate = try await fetchPayload(
                type: .iceCandidate,
                as: IndexICECandidate.self
            )
            iceCandidates.append(remoteICECandidate.iceCandidate)
          
            remainingICECandidates -= 1
            
            if remainingICECandidates == 0 {
                precondition(remoteICECandidate.index == remoteICECandidate.totalNumberOfCandidates - 1)
            }
        }
        return iceCandidates
    }
}

// MARK: - Private

// MARK: - Transport (Private)
private extension SignalServerTransport {
    
    func transportPlaintext<Payload: Encodable & Equatable>(
        payload: Payload,
        type packageType: SignalServerPackageType,
        id: UUID = .init()
    ) async throws {
        try await _transport(type: packageType, payload: payload) { $0 }
    }
    
    func transport<Payload: Encodable & Equatable>(
        encrypting plaintext: Payload,
        type packageType: SignalServerPackageType,
        id: UUID = .init()
    ) async throws {
        try await _transport(type: packageType, payload: plaintext) {
            let data = try jsonEncoder.encode($0)
            return try await encryption.encrypt(data: data)
        }
    }
    
    func _transport<Payload, Transformed>(
        type packageType: SignalServerPackageType,
        id: UUID = .init(),
        payload: Payload,
        transformPayload: (Payload) async throws -> Transformed
    ) async throws where Payload: Encodable & Equatable, Transformed: Encodable & Equatable {
        let transformed: Transformed = try await transformPayload(payload)
        
        let package = OutgoingSignalServerPackage<Transformed>(
            packageType: packageType,
            payload: transformed,
            source: .mobile,
            id: id
        )
        
        let jsonData = try jsonEncoder.encode(package)
        try await networking.send(data: jsonData)
    }
}

// MARK: - Fetch (Private)
private extension SignalServerTransport {
    func fetchPayload<Payload>(
        type packageType: SignalServerPackageType
    ) async throws -> Payload
    where Payload: Decodable & Equatable
    {
        try await fetchPayload(type: packageType, as: Payload.self)
    }
    
    func fetchPayload<Payload>(
        type packageType: SignalServerPackageType,
        as payloadType: Payload.Type
    ) async throws -> Payload
    where Payload: Decodable & Equatable
    {
        var fetchedPayload: Payload?
       
        let stream = networking.incomingMessages
            .compactMap { [self] (data: Data) throws -> Payload? in
                let message = try jsonDecoder
                    .decode(IncomingSimpleSignalServerPackage.self, from: data)
                
                guard message.packageType == packageType && message.source == .browserExtension else {
                    return nil
                }
                
                let messageWithPayload = try jsonDecoder
                    .decode(IncomingSignalServerPackage<Payload>.self, from: data)
                
                return messageWithPayload.payload
            }
        
        for try await payload in stream {
            fetchedPayload = payload
            break
        }
        return fetchedPayload!
    }
}


