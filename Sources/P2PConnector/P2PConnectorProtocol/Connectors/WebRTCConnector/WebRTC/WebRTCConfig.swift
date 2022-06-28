//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-28.
//

import Foundation

public struct WebRTCConfig {
    public let stunServers: [String]
    public init(stunServers: [String] = ["stun:stunprotocol.org"]) {
        self.stunServers = stunServers
    }
    public static let `default` = Self()
}
