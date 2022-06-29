//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-29.
//

import Foundation

public protocol QRCodeDisplayingProtocol {
    func display<Description>(qrCodeImage: QRCodeImage<Description>) async throws
}
