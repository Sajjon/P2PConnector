//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-29.
//

import Foundation

public enum QRInputCorrectionLevel: Int, Hashable, CaseIterable, Identifiable, CustomStringConvertible {
    
    public typealias ID = RawValue
    public var id: ID { rawValue }
    
    /// Level Low 7%.
    case low7 = 7
    
    /// Level Medium 15%.
    case medium15 = 15
    
    /// Level Q 25%
    case q = 25
    
    /// Level High 30%.
    case high30 = 30
    
    public static let `default`: Self = .medium15
    
    public var description: String {
        switch self {
        case .low7:  return "L 7"
        case .medium15: return "M 15"
        case .q: return "Q 25"
        case .high30: return "H 30"
        }
    }
    
    public var value: String {
        switch self {
        case .high30: return "H"
        case .low7: return "L"
        case .q: return "Q"
        case .medium15: return "M"
        }
    }

}
