//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-28.
//

import Foundation

public let nanosecondsPerMillisecond: TimeInterval = 1_000_000

public struct Offer: Codable, Equatable {
    public let sdp: String
}

public struct Answer: Codable, Equatable {
    public let sdp: String
}

public struct ICECandidate: Codable, Equatable {
    public let sdp: String
    public let lineIndex: Int32
}

public enum GenerateICECandidatesMode {
    // FIXME: change `DispatchTimeInterval` to new Clock, Time, Duration API once we can target iOS 16: https://developer.apple.com/documentation/swift/time-and-duration
    case asManyAsPossibleDuring(durationInMilliseconds: TimeInterval)
}

public protocol WebRTCProtocol {
    func createOffer() async throws -> Offer
    func iceCandidates(mode: GenerateICECandidatesMode) async throws -> [ICECandidate]
    func setAnswerFromRemoteClient(_ answer: Answer) async throws
    func setRemoteICECandidates(_ remoteICECandidates: [ICECandidate]) async throws
    func channel() async throws -> P2PCommunicationChannel
}

