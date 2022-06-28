//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-28.
//

import Foundation

public protocol TransportProtocol {
    func transport(offer: Offer) async throws
    func transport(iceCandidates: [ICECandidate]) async throws
    func fetchAnswer() async throws -> Answer
    func fetchICECandidates() async throws -> [ICECandidate]
}
