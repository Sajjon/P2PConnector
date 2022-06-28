//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-28.
//

import Foundation


public actor SimpleP2PChannel: P2PCommunicationChannel {
    public let incommingMessages: AsyncStream<Data>
  
    private let _sendData: SendData
    
    public init(
        incommingMessages: AsyncStream<Data>,
        sendData: @escaping SendData
    ) {
        self.incommingMessages = incommingMessages
        self._sendData = sendData
    }
    
}

public extension SimpleP2PChannel {
    typealias SendData = (Data) async throws -> Void
   
    func send(data: Data) async throws {
        try await _sendData(data)
    }
}
