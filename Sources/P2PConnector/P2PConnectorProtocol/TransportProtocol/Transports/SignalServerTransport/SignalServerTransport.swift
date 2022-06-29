//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-28.
//

import Foundation

public protocol NetworkingProtocol {
    
    /// Either websocket send or RESTFul POST/GET
    func send(data: Data) async throws
    
    /// Either a websocket subscription or poll based RESTFul request
    var incomingMessages: AsyncStream<Data> { get }
}

public actor SignalServerTransport: TransportProtocol {
    
    private let networking: NetworkingProtocol
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder
    
    public init(
        networking: NetworkingProtocol,
        jsonEncoder: JSONEncoder = .init(),
        jsonDecoder: JSONDecoder = .init()
    ) {
        self.networking = networking
        self.jsonEncoder = jsonEncoder
        self.jsonDecoder = jsonDecoder
    }
    
}

public extension SignalServerTransport {
  
    func transport(offer: Offer) async throws {
        try await transport(
            payload: offer,
            type: .offer
        )
    }
    
    func transport(iceCandidates: [ICECandidate]) async throws {
        for iceCandidate in iceCandidates {
            try await transport(
                payload: iceCandidate,
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

public enum WebRTCPackageSource: Codable, Equatable {
    case mobile
    case browserExtension
}

public struct IncomingSimpleSignalServerPackage: Decodable, Equatable {
    public let packageType: WebRTCPackageType
    public let source: WebRTCPackageSource
    public let id: UUID
}

public struct IncomingSignalServerPackage<Payload>: Decodable, Equatable
    where Payload: Decodable & Equatable
{
    public let packageType: WebRTCPackageType
    public let source: WebRTCPackageSource
    public let payload: Payload
    public let id: UUID
}

public struct OutgoingSignalServerPackage<Payload>: Encodable, Equatable
    where Payload: Encodable & Equatable
{
    public let packageType: WebRTCPackageType
    public let payload: Payload
    public let source: WebRTCPackageSource
    public let id: UUID
}

private extension SignalServerTransport {
    
    func transport<Payload: Codable & Equatable>(
        payload: Payload,
        type packageType: WebRTCPackageType,
        id: UUID = .init()
    ) async throws {
        let package = OutgoingSignalServerPackage(
            packageType: packageType,
            payload: payload,
            source: .mobile,
            id: id
        )
        let jsonData = try jsonEncoder.encode(package)
        try await networking.send(data: jsonData)
    }
    
    func fetchPayload<Payload>(
        type packageType: WebRTCPackageType
    ) async throws -> Payload
    where Payload: Decodable & Equatable
    {
        try await fetchPayload(type: packageType, as: Payload.self)
    }
    
    func fetchPayload<Payload>(
        type packageType: WebRTCPackageType,
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

public struct IndexICECandidate: Codable, Equatable {
    public let iceCandidate: ICECandidate
    public let index: Int
    public let totalNumberOfCandidates: Int
}
