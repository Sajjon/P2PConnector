//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-29.
//

import Foundation

public struct IncomingSimpleSignalServerPackage: Decodable, Equatable {
    public let packageType: SignalServerPackageType
    public let source: WebRTCPackageSource
    public let id: UUID
}
