//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-29.
//

import Foundation

public enum WebRTCPackageType: String, Equatable, Codable {
    case offer
    case answer
    case iceCandidate
}
