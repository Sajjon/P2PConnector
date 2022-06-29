//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-29.
//

import Foundation

public protocol QRCodeScanningProtocol {
    func scan<Description>() async throws -> QRCodeScanned<Description>
}
