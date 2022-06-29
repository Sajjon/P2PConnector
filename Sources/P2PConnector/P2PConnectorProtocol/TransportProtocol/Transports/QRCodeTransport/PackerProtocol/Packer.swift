//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-29.
//

import Foundation

public final class Packer: PackerProtocol {
    
    private let byteCutOffThreshold: Int
    private let jsonEncoder: JSONEncoder
    
    public init(
        byteCutOffThreshold: Int = 256,
        jsonEncoder: JSONEncoder = .init()
    ) {
        self.byteCutOffThreshold = byteCutOffThreshold
        self.jsonEncoder = jsonEncoder
    }
    public static func `default`(
        byteCutOffThreshold: Int = 256,
        jsonEncoder: JSONEncoder = .init()
    ) -> Self { .init(byteCutOffThreshold: byteCutOffThreshold, jsonEncoder: jsonEncoder) }
}
public extension Packer {
    
    func pack<Content, Description>(
        content: Content,
        describe: (Payload) throws -> Description
    ) async throws -> [Package<Description>] where Content: Encodable {
    
        let jsonData = try jsonEncoder.encode(content)
       
        let chunks = jsonData.chunks(ofCount: byteCutOffThreshold)
      
        let packages: [Package<Description>] = try chunks.enumerated()
            .map { (index, data) in
                let payload = Payload(
                    data: data,
                    payloadDescription: .init(
                        byteOffset: index * byteCutOffThreshold,
                        byteCountTotal: jsonData.count,
                        payloadIndex: index,
                        totalPayloadCount: chunks.count
                    )
                )
                let description = try describe(payload)
                let package = Package(
                    packageDescription: description,
                    payload: payload
                )
                return package
            }
           
        return packages
        
    }
}
