//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-29.
//

import Foundation
import CoreGraphics

public protocol QRCodeGeneratorProtocol {
    func generateQR(data: Data, errorCorrectionLevel: QRCodeErrorCorrectionLevel, size: CGSize?) async throws -> CGImage
}

public extension QRCodeGeneratorProtocol {
    
    func generateQR(
        data: Data,
        errorCorrectionLevel: QRCodeErrorCorrectionLevel = .l,
        size: CGSize? = nil
    ) async throws -> CGImage {
        try await generateQR(data: data, errorCorrectionLevel: errorCorrectionLevel, size: size)
    }
}

