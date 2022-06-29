//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-29.
//

import Foundation

public protocol PackerProtocol {
  
    func pack<Content, Description>(
        content: Content,
        describe: (Payload) throws -> Description
    ) async throws -> [Package<Description>] where Content: Encodable
}

public extension PackerProtocol where Self == Packer {
    static var `default`: some PackerProtocol {
        Packer.default()
    }
}
