//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-29.
//

import Foundation

public struct QRPackageDescription: Equatable, Codable {
    public let packageType: WebRTCPackageType
    public let id: String
    
    public init(
        type packageType: WebRTCPackageType,
        id: String
    ) {
        self.packageType = packageType
        self.id = id
    }
}
