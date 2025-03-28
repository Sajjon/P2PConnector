//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-28.
//

import Foundation
@testable import P2PConnector

public final class MockSignalServerTransport: TransportProtocol {
  
    internal let connectionID: ConnectionID
    internal let encryption: EncryptionProtocol
    internal let sendData: SendData
    internal let fetchData: FetchData
   
    typealias SendData = (ConnectionID, Data) async throws -> Void
    typealias FetchData = (ConnectionID) async throws -> Data
    
    init(
        connectionID: ConnectionID,
        encryption: EncryptionProtocol,
        sendData: @escaping SendData,
        fetchData: @escaping FetchData
    ) {
        self.connectionID = connectionID
        self.encryption = encryption
        self.sendData = sendData
        self.fetchData = fetchData
    }
    
}

public extension MockSignalServerTransport {
    
    func initialize() async throws {
        try await Task.sleep(nanoseconds: 10)
    }
  
    func transport(offer: Offer) async throws {
        try await Task.sleep(nanoseconds: 10)
    }
 
    func transport(iceCandidates: [ICECandidate]) async throws {
        try await Task.sleep(nanoseconds: 10)
    }
   
    func fetchAnswer() async throws -> Answer {
        try await Task.sleep(nanoseconds: 10)
        return Answer(sdp: "Mocked ANSWER from Extension")
    }
    
    func fetchICECandidates() async throws -> [ICECandidate] {
        let indices = (0..<minNumberOfCandidates).map { $0 + iceCandidateFromExtensionOffset }
        return indices.map { ICECandidate.init(sdp: "Mocked ICECandidate from extension", lineIndex: $0) }
    }
}
