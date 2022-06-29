//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-29.
//

import Foundation

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
