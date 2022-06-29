//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-28.
//

import Foundation
import CoreGraphics
import Algorithms


public actor QRCodeTransport: TransportProtocol {
  
    private let qrCodeScanning: QRCodeScanningProtocol
    private let qrCodeParser: QRCodeParserProtocol
    private let qrCodeDisplaying: QRCodeDisplayingProtocol
    
    private let qrCodesContentSplitter: QRContentSplitterProtocol
    
//    private let qrCodeGenerator: QRCodeGeneratorProtocol
//    private let packer: PackerProtocol
//    private let jsonEncoder: JSONEncoder
    
    public init(
        qrCodeScanning: QRCodeScanningProtocol,
        qrCodeDisplaying: QRCodeDisplayingProtocol,
        qrCodeParser: QRCodeParserProtocol = .default,
//        qrCodeGenerator: QRCodeGeneratorProtocol = .default,
//        packer: PackerProtocol = .default,
//        jsonEncoder: JSONEncoder = .init()
        qrCodesContentSplitter: QRContentSplitterProtocol = .default
       
    ) {
        self.qrCodeScanning = qrCodeScanning
        self.qrCodeDisplaying = qrCodeDisplaying
        self.qrCodeParser = qrCodeParser
//        self.qrCodeGenerator = qrCodeGenerator
//        self.packer = packer
//        self.jsonEncoder = jsonEncoder
        self.qrCodesContentSplitter = qrCodesContentSplitter
    }
}


// MARK: - Public

// MARK: - TransportProtocol (Public)
public extension QRCodeTransport {
    
    func initialize() async throws {
       /* nothing to do? */
    }
 
    func transport(offer: Offer) async throws {
        try await transport(content: offer, type: .offer)
    }
   
    func transport(iceCandidates: [ICECandidate]) async throws {
        for (index, iceCandidate) in iceCandidates.enumerated() {
            try await transport(
                content: iceCandidate,
                type: .iceCandidate,
                id: index.description
            )
        }
    }
   
    func fetchAnswer() async throws -> Answer {
        try await fetch(type: .answer).content
    }
   
    /// N.B. This REQUIRES that browserExtension batches ICECandidates and
    /// are aware of how many candidates it batched during some duration when
    /// it transports the first candidate to the mobile client.
    func fetchICECandidates() async throws -> [ICECandidate] {
       
        var iceCandidates: [ICECandidate] = []
       
        let (firstRemoteICECandidate, payloadDescription, _) = try await fetch(
            type: .iceCandidate,
            as: ICECandidate.self
        )
       
        iceCandidates.append(firstRemoteICECandidate)
       
        var remainingICECandidates = payloadDescription.totalPayloadCount - 1 // minus one because we just got the first...
       
        while remainingICECandidates > 0 {
            let (remoteICECandidate, payloadDescription, _) = try await fetch(
                type: .iceCandidate,
                as: ICECandidate.self
            )
            iceCandidates.append(remoteICECandidate)
            remainingICECandidates -= 1
            
            if remainingICECandidates == 0 {
                precondition(payloadDescription.isLastPayloadForContent)
            }
        }
        return iceCandidates
    }
}

// MARK: - Error
public extension QRCodeTransport {
    enum Error: Swift.Error {
        case expectedToScanQRCode(
            forType: WebRTCPackageType,
            butGot: WebRTCPackageType
        )
    }
}


// MARK: - Private
private extension QRCodeTransport {
    
    func scan() async throws -> QRCodeScanned {
        try await qrCodeScanning.scan()
    }
}

internal extension QRCodeTransport {
    typealias Package = P2PConnector.Package<QRPackageDescription>
    typealias QRCodeImage = P2PConnector.QRCodeImage<QRPackageDescription>
    typealias QRCodeScanned = P2PConnector.QRCodeScanned<QRPackageDescription>
}

public protocol QRContentSplitterProtocol {
    func splitContentIntoQRCodes<Content: Codable, Description: Encodable>(
        _ content: Content,
        type packageType: WebRTCPackageType,
        id: String,
        describe: (Payload) throws -> Description
    ) async throws -> [QRCode<Description, CGImage>]
}
public extension QRContentSplitterProtocol where Self ==  QRContentSplitter{
    static var `default`: some QRContentSplitterProtocol {
        QRContentSplitter.default
    }
}
public actor QRContentSplitter: QRContentSplitterProtocol {
    private let packer: PackerProtocol
    private let qrCodeGenerator: QRCodeGeneratorProtocol
    private let jsonEncoder: JSONEncoder
   
    public init(
        packer: PackerProtocol = .default,
        qrCodeGenerator: QRCodeGeneratorProtocol = .default,
        jsonEncoder: JSONEncoder = .init()
    ) {
        self.packer = packer
        self.qrCodeGenerator = qrCodeGenerator
        self.jsonEncoder = jsonEncoder
    }
    public static let `default` = QRContentSplitter()
}
public extension QRContentSplitter {
    func splitContentIntoQRCodes<Content: Codable, Description: Encodable>(
        _ content: Content,
        type packageType: WebRTCPackageType,
        id: String,
        describe: (Payload) throws -> Description
    ) async throws -> [QRCode<Description, CGImage>] {
        let packages: [Package] = try await packer.pack(content: content, describe: describe)
        
        let qrCodeImages: [QRCode<Description, CGImage>] = try await packages.asyncMap { package in
            let json = try jsonEncoder.encode(package)
            let image = try await qrCodeGenerator.generateQR(data: json)
            
            let qrCodeImage = QRCodeImage(
                description: package.packageDescription,
                content: image
            )
            
            return qrCodeImage
        }
        
        return qrCodeImages
    }
}


// MARK: - Transport
private extension QRCodeTransport {
    
    func transport<Content: Codable>(
        content: Content,
        type packageType: WebRTCPackageType,
        id: String = UUID().uuidString
    ) async throws {
        let qrCodeImages = try await qrCodesContentSplitter.splitContentIntoQRCodes(content, type: packageType, id: id) { payload in
            QRPackageDescription(type: packageType, id: id)
        }

        
        for qrCodeImage in qrCodeImages {
            try await qrCodeDisplaying.display(qrCodeImage: qrCodeImage)
        }
    }
}

// MARK: - Fetch
private extension QRCodeTransport {
    func fetch<Content: Codable>(
        type packageType: WebRTCPackageType
    ) async throws -> (
        content: Content,
        payloadDescription: PayloadDescription,
        packageDescription: QRPackageDescription
    ) {
        try await fetch(type: packageType, as: Content.self)
    }
    
    func fetch<Content: Codable>(
        type packageType: WebRTCPackageType,
        as contenType: Content.Type
    ) async throws -> (
        content: Content,
        payloadDescription: PayloadDescription,
        packageDescription: QRPackageDescription
    ) {
        var scannedContent = Data()
        var isLast = false
        while !isLast {
            debugPrint("📸 🏁 scanning QR code")
            let scanned = try await scan()
            debugPrint("📸 🏁 scanned QR code => parsing")
            let parsed = try await qrCodeParser.parse(code: scanned)
            debugPrint("📸 🏁 parsed QR code => appending contents")
            scannedContent += parsed.content.data
            isLast = parsed.content.payloadDescription.isLastPayloadForContent
            precondition(scannedContent.count == parsed.content.payloadDescription.byteCountTotal, "scannedContent.count=\(scannedContent.count) != parsed.content.payloadDescription.byteCountTotal=\(parsed.content.payloadDescription.byteCountTotal)")
        }
        debugPrint("📸 🏁 reassembled contents => decoding to `Package`")
        let package = try JSONDecoder().decode(Package.self, from: scannedContent)
        debugPrint("📸 🏁 Decoding as `Package` => checking package type")

        guard package.packageDescription.packageType == packageType else {
            throw Error.expectedToScanQRCode(
                forType: packageType,
                butGot: package.packageDescription.packageType
            )
        }
        debugPrint("📸 🏁 `Package` has correct package type \(packageType) => decoding `package.payload.data` as \(Content.self)")
        
        let payloadData = package.payload.data
        let content = try JSONDecoder().decode(Content.self, from: payloadData)
        debugPrint("📸 🏁 `Decoding `package.payload.data` as \(Content.self) => returning content as FETCHED.")
        return (content: content, payloadDescription: package.payload.payloadDescription, packageDescription: package.packageDescription)
    }
}
