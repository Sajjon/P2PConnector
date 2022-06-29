//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-28.
//

import Foundation

public protocol NetworkingProtocol {
    
    func connect() async
    
    /// Either websocket send or RESTFul POST/GET
    func send(data: Data) async throws
    
    /// Either a websocket subscription or poll based RESTFul request
    var incomingMessages: AsyncStream<Data> { get }
}

public actor WebSocket: NetworkingProtocol {
    
    
    public let incomingMessages: AsyncStream<Data>
    private var incomingMessagesContinuation: AsyncStream<Data>.Continuation
   
    private let webSocketTask: URLSessionWebSocketTask
    
    init(
        webSocketServerURL: URL,
        session: URLSession = .shared
    ) {
        self.webSocketTask = session.webSocketTask(with: webSocketServerURL)
        
        var incomingMessagesContinuation: AsyncStream<Data>.Continuation?
        let incomingMessages = AsyncStream<Data> { continuation in
            incomingMessagesContinuation = continuation
        }
     
        self.incomingMessages = incomingMessages
        self.incomingMessagesContinuation = incomingMessagesContinuation!
    }
}
public extension WebSocket {
    
    func connect() async {
        webSocketTask.resume()
        Task.detached { [self] in
            try await self.receiveMessage()
        }
    }
    
    func send(data: Data) async throws {
        try await webSocketTask.send(.data(data))
    }
}
private extension WebSocket {
    
    func receiveMessage() async throws {
        let message = try await webSocketTask.receive()
        switch message {
        case let .data(data):
            received(data: data)
        case let .string(string):
            received(data: string.data(using: .utf8)!)
        default: break
        }
        try await receiveMessage()
    }
    
    private func received(data: Data) {
        incomingMessagesContinuation.yield(data)
    }
}

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

private struct Subscribe: Codable, Equatable {
    let connectionID: ConnectionID
}
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

public enum WebRTCPackageSource: Codable, Equatable {
    case mobile
    case browserExtension
}

public struct IncomingSimpleSignalServerPackage: Decodable, Equatable {
    public let packageType: SignalServerPackageType
    public let source: WebRTCPackageSource
    public let id: UUID
}

public struct IncomingSignalServerPackage<Payload>: Decodable, Equatable
    where Payload: Decodable & Equatable
{
    public let packageType: SignalServerPackageType
    public let source: WebRTCPackageSource
    public let payload: Payload
    public let id: UUID
}

public struct OutgoingSignalServerPackage<Payload>: Encodable, Equatable
    where Payload: Encodable & Equatable
{
    public let packageType: SignalServerPackageType
    public let payload: Payload
    public let source: WebRTCPackageSource
    public let id: UUID
}

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

public struct IndexICECandidate: Codable, Equatable {
    public let iceCandidate: ICECandidate
    public let index: Int
    public let totalNumberOfCandidates: Int
}

public enum SignalServerPackageType: String, Equatable, Codable {
    case answer
    case offer
    case iceCandidate
    case subscribe
}
