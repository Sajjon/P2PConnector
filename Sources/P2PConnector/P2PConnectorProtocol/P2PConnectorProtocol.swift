//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-28.
//

import Foundation

public protocol P2PConnectorProtocol {
    func establishP2PConnection() async throws -> P2PCommunicationChannel
}
