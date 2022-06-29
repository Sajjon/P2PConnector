//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-29.
//

import Foundation

public extension JSONDecoder {
    convenience init(dataDecodingStrategy: DataDecodingStrategy) {
        self.init()
        self.dataDecodingStrategy = dataDecodingStrategy
    }
    static let hex = JSONDecoder(dataDecodingStrategy: .hex)
}
public extension JSONEncoder.DataEncodingStrategy {
    static var hex: Self {
        .custom({(data: Data, encoder: Encoder) throws in
            var container = encoder.singleValueContainer()
            try container.encode(data.hexEncodedString())
        })
    }
}
public extension JSONEncoder {
    convenience init(
        dataEncodingStrategy: DataEncodingStrategy,
        outputFormatting: OutputFormatting = [.prettyPrinted, .sortedKeys]
    ) {
        self.init()
        self.dataEncodingStrategy = dataEncodingStrategy
        self.outputFormatting = outputFormatting
    }
    static let hex = JSONEncoder(dataEncodingStrategy: .hex)
}

public extension JSONDecoder.DataDecodingStrategy {
    static var hex: Self {
        .custom({ decoder throws -> Data in
            let container = try decoder.singleValueContainer()
            let hexString = try container.decode(String.self)
            return try Data(hexString: hexString)
        })
    }
}
