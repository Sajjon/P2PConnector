//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-29.
//

import Foundation
@testable import P2PConnector
import XCTest

final class MockedQRCodeScanner: QRCodeScanningProtocol {
    typealias QRScanned = QRCodeTransport.QRCodeScanned
    private let mockScanResult: () -> any Encodable
    
    init(mockScanResult: @escaping () -> any Encodable) {
        self.mockScanResult = mockScanResult
    }
    
    func scan<Description>() async throws -> QRCodeScanned<Description> {
        fatalError()
    }
}

final class MockedQRDisplayer: QRCodeDisplayingProtocol {
    typealias QRImage = QRCodeTransport.QRCodeImage
    private let interceptor: (QRImage) -> Void
    init(interceptor: @escaping (QRImage) -> Void) {
        self.interceptor = interceptor
    }
    func display<Description>(qrCodeImage: QRCodeImage<Description>) async throws {
        fatalError()
    }
}

final class QRCodeTransportTests: XCTestCase {
    typealias Package = QRCodeTransport.Package
    
    func test_qrCodeTransport() async {
        
        var displayedQRImage: [MockedQRDisplayer.QRImage] = []
        let mockedQRDisplayer = MockedQRDisplayer {
            displayedQRImage.append($0)
        }
        
//        let qrTransport = QRCodeTransport(
//            qrCodeScanning: mockedQRCodeScanning,
//            qrCodeDisplaying: mockedQRDisplayer
//        )
//        
//        let mockP2PChannel = MockedP2PChannel()
//        
//        let mockedWebRTC = MockWebRTC(
//            webRTCConfig: WebRTCConfig.default,
//            mockedP2PChannel: mockP2PChannel
//        )
//        
//        let webRTCConnector = WebRTCConnector(
//            webRTC: mockedWebRTC,
//            transport: qrTransport
//        )
//        
//        let channel = try await webRTCConnector.establishP2PConnection()
    }
    
}
