//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-29.
//

import Foundation

public struct IncomingSignalServerPackage<Payload>: Decodable, Equatable
    where Payload: Decodable & Equatable
{
    public let packageType: SignalServerPackageType
    public let source: WebRTCPackageSource
    public let payload: Payload
    public let id: UUID
}
