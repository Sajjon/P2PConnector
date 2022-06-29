//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-29.
//

import Foundation

public struct PayloadDescription: Codable, Equatable {
    
    /// Byte offset
    public let byteOffset: Int
    
    /// Total byte count of split package
    public let byteCountTotal: Int
    
    /// `n:th` payload of some large package, this is the index of this payload, not byte offset
    public var payloadIndex: Int
    
    public let totalPayloadCount: Int
    
    public var isLastPayloadForContent: Bool {
       payloadIndex + 1 == totalPayloadCount
    }
}
