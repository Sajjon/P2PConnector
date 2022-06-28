//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-28.
//

import Foundation

public protocol EncryptionProtocol {
    func encrypt(data: Data) async throws -> Data
    func decrypt(data: Data) async throws -> Data
}
