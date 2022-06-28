//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-28.
//

import Foundation
import P2PConnector

public final class MockEncryption: EncryptionProtocol {
    internal let _encrypt: Encrypt
    internal let _decrypt: Decrypt
    
    public init(
        encrypt: @escaping Encrypt,
        decrypt: @escaping Decrypt
    ) {
        self._encrypt = encrypt
        self._decrypt = decrypt
    }
}

public extension MockEncryption {
    
    typealias Encrypt = (Data) async throws -> Data
    typealias Decrypt = (Data) async throws -> Data
    
    func encrypt(data: Data) async throws -> Data {
       try await _encrypt(data)
    }
    
    func decrypt(data: Data) async throws -> Data {
        try await _decrypt(data)
    }
}
