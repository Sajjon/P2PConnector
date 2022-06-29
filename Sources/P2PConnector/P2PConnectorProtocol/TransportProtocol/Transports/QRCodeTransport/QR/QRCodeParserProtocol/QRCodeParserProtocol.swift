//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-29.
//

import Foundation

public protocol QRCodeParserProtocol {
    func parse<Description>(code: QRCodeScanned<Description>) async throws -> QRCodeParsed<Description>
}

public extension QRCodeParserProtocol where Self == QRCodeParser {
    static var `default`: some QRCodeParserProtocol {
        QRCodeParser.default()
    }
}
