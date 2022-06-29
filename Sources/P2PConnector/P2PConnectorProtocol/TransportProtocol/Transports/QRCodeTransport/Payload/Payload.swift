//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-29.
//

import Foundation

public struct Payload: Codable, Equatable {
    public let data: Data
    public let payloadDescription: PayloadDescription
}
