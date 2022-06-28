//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-28.
//

import Foundation

public actor SignalServerTransport: TransportProtocol {}

public extension SignalServerTransport {
  
    func transport(offer: Offer) async throws {
        fatalError()
    }
    
    func transport(iceCandidates: [ICECandidate]) async throws {
        fatalError()
    }
    
    func fetchAnswer() async throws -> Answer {
        fatalError()
    }
    
    func fetchICECandidates() async throws -> [ICECandidate] {
        fatalError()
    }
}
