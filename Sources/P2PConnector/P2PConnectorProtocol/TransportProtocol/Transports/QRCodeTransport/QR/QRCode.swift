//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-29.
//

import Foundation
import CoreGraphics

public struct QRCode<Description, Content> {
    public let description: Description
    public let content: Content
}

public typealias QRCodeImage<Description> = QRCode<Description, CGImage>
public typealias QRCodeScanned<Description> = QRCode<Description, String>
public typealias QRCodeParsed<Description> = QRCode<Description, Payload>
