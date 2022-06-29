//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftCrypto open source project
//
// Copyright (c) 2019-2020 Apple Inc. and the SwiftCrypto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.md for the list of SwiftCrypto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

// https://github.com/apple/swift-crypto/blob/main/Sources/Crypto/Util/PrettyBytes.swift

import Foundation

enum ByteHexEncodingErrors: Error {
	case incorrectHexValue
	case incorrectString
}

let charA = UInt8(UnicodeScalar("a").value)
let char0 = UInt8(UnicodeScalar("0").value)

private func htoi(_ value: UInt8) throws -> UInt8 {
	switch value {
	case char0...char0 + 9:
		return value - char0
	case charA...charA + 5:
		return value - charA + 10
	default:
		throw ByteHexEncodingErrors.incorrectHexValue
	}
}

public extension Data {
	init(hexString: String) throws {
		self.init()

		if hexString.count % 2 != 0 || hexString.count == 0 {
			throw ByteHexEncodingErrors.incorrectString
		}

		let stringBytes: [UInt8] = Array(hexString.data(using: String.Encoding.utf8)!)

		for i in 0...((hexString.count / 2) - 1) {
			let char1 = stringBytes[2 * i]
			let char2 = stringBytes[2 * i + 1]

			try self.append(htoi(char1) << 4 + htoi(char2))
		}
	}

}

public extension Data {
	struct HexEncodingOptions: OptionSet {
		public typealias RawValue = Int
		public let rawValue: RawValue
		public init(rawValue: RawValue) {
			self.rawValue = rawValue
		}
		public static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
	}

	func hexEncodedString(options: HexEncodingOptions = []) -> String {
		let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
		return self.map { String(format: format, $0) }.joined()
	}
}

public extension FixedWidthInteger {
	var data: Data {
		let data = withUnsafeBytes(of: self.bigEndian) { Data($0) }
		return data
	}
}
