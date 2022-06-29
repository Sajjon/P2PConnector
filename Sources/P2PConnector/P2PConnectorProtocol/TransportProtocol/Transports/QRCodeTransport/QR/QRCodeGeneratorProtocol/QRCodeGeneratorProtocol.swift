//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-29.
//

import Foundation
import CoreGraphics

public protocol QRCodeGeneratorProtocol {
    func generateQR(data: Data, errorCorrectionLevel: QRInputCorrectionLevel, size: CGSize?) async throws -> CGImage
}

public extension QRCodeGeneratorProtocol {
    
    func generateQR(
        data: Data,
        errorCorrectionLevel: QRInputCorrectionLevel = .high30,
        size: CGSize? = nil
    ) async throws -> CGImage {
        try await generateQR(data: data, errorCorrectionLevel: errorCorrectionLevel, size: size)
    }
}

public extension QRCodeGeneratorProtocol where Self == QRCodeGenerator {
    static var `default`: some QRCodeGeneratorProtocol { QRCodeGenerator.default }
}
