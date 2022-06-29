//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-29.
//

import Foundation

public enum SignalServerPackageType: String, Equatable, Codable {
    case answer
    case offer
    case iceCandidate
    case subscribe
}
