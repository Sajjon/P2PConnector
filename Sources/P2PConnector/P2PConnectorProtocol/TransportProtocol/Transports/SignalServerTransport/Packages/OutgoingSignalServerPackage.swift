//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-29.
//

import Foundation

public struct OutgoingSignalServerPackage<Payload>: Encodable, Equatable
    where Payload: Encodable & Equatable
{
    public let packageType: SignalServerPackageType
    public let payload: Payload
    public let source: WebRTCPackageSource
    public let id: UUID
}
