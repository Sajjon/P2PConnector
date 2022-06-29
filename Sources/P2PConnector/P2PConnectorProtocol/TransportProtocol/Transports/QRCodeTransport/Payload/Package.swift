//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-29.
//

import Foundation

public struct Package<Description> {
    public let packageDescription: Description
    public let payload: Payload
}

extension Package: Encodable where Description: Encodable {}
extension Package: Decodable where Description: Decodable {}
