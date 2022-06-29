//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-29.
//

import Foundation

public final class FakedNonDeterministicWebRTC {
}


public actor WrappedWebRTC: WebRTCProtocol {
    
}

public extension WrappedWebRTC {
    func createOffer() async throws -> Offer {
        fatalError()
    }
    func iceCandidates(mode: GenerateICECandidatesMode) async throws -> [ICECandidate] {
        fatalError()
    }
    func setAnswerFromRemoteClient(_ answer: Answer) async throws {
        fatalError()
    }
    func setRemoteICECandidates(_ remoteICECandidates: [ICECandidate]) async throws {
        fatalError()
    }
    func channel() async throws -> P2PCommunicationChannel {
        fatalError()
    }
}
