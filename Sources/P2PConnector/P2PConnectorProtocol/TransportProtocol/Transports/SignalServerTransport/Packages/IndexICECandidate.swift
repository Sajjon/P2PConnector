//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-29.
//

import Foundation

public struct IndexICECandidate: Codable, Equatable {
    public let iceCandidate: ICECandidate
    public let index: Int
    public let totalNumberOfCandidates: Int
}
