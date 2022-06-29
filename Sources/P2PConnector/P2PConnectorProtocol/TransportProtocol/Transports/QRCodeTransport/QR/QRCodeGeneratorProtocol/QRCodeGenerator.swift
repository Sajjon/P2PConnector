//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-29.
//

import Foundation
import CoreGraphics
import CoreImage.CIFilterBuiltins

public struct QRCodeGenerator: QRCodeGeneratorProtocol {

    public init() {}
    public static let `default` = Self()
}

// MARK: - Public


// MARK: - QRCodeGeneratorProtocol (Public)
public extension QRCodeGenerator {
    func generateQR(
        data: Data,
        errorCorrectionLevel: QRInputCorrectionLevel,
        size: CGSize?
    ) async throws -> CGImage {
        try await Task(priority: .background) {
            let cgImage = try syncGenerateQR(
                data: data,
                size: size,
                inputCorrectionLevel: errorCorrectionLevel.value
            )
            return cgImage
        }.value
    }
}


private func syncGenerateQR(
    data: Data,
    size maybeSize: CGSize?,
    inputCorrectionLevel: String
) throws -> CGImage {
    let size = maybeSize ?? CGSize(width: 300, height: 300)
    let filter = CIFilter.qrCodeGenerator()
    
    filter.message = data
    filter.correctionLevel = inputCorrectionLevel
    
    guard
        let outputImage = filter.outputImage
    else {
        throw GenerateQRCodeError.failedToGenerateQRCodeOutputImageIsNil
        
    }
    
    let x = size.width / outputImage.extent.size.width
    let y = size.height / outputImage.extent.size.height
    let scaled = outputImage.transformed(by: CGAffineTransform(scaleX: x, y: y))
    
    guard
        let cgImage = CIContext().createCGImage(scaled, from: scaled.extent)
    else {
        throw GenerateQRCodeError.failedToGenerateQRFailedToCreateImageFromContext
    }
    return cgImage
}

public enum GenerateQRCodeError: Swift.Error {
    case failedToGenerateQRCodeOutputImageIsNil
    case failedToGenerateQRFailedToCreateImageFromContext
}
