//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-29.
//

import Foundation

public final class QRCodeParser: QRCodeParserProtocol {

    private let jsonDecoder: JSONDecoder
    public init(jsonDecoder: JSONDecoder = .init()) {
        self.jsonDecoder = jsonDecoder
    }
    public static func `default`(jsonDecoder: JSONDecoder = .init()) -> Self {
        self.init(jsonDecoder: jsonDecoder)
    }
}

public extension QRCodeParser {
    func parse<Description>(code: QRCodeScanned<Description>) async throws -> QRCodeParsed<Description> {
        let jsonData = code.content.data(using: .utf8)!
        debugPrint("✨QRCodeParser: got `jsonData`: \(code.content) => decoding as `Payload.self`")
        let payload = try jsonDecoder.decode(Payload.self, from: jsonData)
        debugPrint("✨Decoding as `Payload.self => returning`")
        return QRCodeParsed(
            description: code.description,
            content: payload
        )
    }
}
