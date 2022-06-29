//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-28.
//

import Foundation
import CoreGraphics
import Algorithms





public protocol QRCodeParserProtocol {
    func parse<Description>(code: QRCodeScanned<Description>) async throws -> QRCodeParsed<Description>
}

public actor QRCodeTransport<Description>: TransportProtocol {
  
    private let qrCodeGenerator: QRCodeGeneratorProtocol
    private let qrCodeScanning: QRCodeScanningProtocol
    private let qrCodeParser: QRCodeParserProtocol
    private let qrCodeDisplaying: QRCodeDisplayingProtocol
    private let packer: PackerProtocol
//    private let unpacker: UnpackerProtocol
    private let jsonEncoder: JSONEncoder
    
    public init(
        qrCodeGenerator: QRCodeGeneratorProtocol,
        qrCodeScanning: QRCodeScanningProtocol,
        qrCodeDisplaying: QRCodeDisplayingProtocol,
        qrCodeParser: QRCodeParserProtocol,
        packer: PackerProtocol,
//        unpacker: UnpackerProtocol,
        jsonEncoder: JSONEncoder = .init()
       
    ) {
        self.qrCodeGenerator = qrCodeGenerator
        self.qrCodeScanning = qrCodeScanning
        self.qrCodeDisplaying = qrCodeDisplaying
        self.qrCodeParser = qrCodeParser
        self.packer = packer
//        self.unpacker = unpacker
        self.jsonEncoder = jsonEncoder
    }
}


public struct QRPackageDescription: Equatable, Codable {
    public let packageType: WebRTCPackageType
    public let id: String
    
    public init(
        type packageType: WebRTCPackageType,
        id: String
    ) {
        self.packageType = packageType
        self.id = id
    }
}

private extension QRCodeTransport {
    typealias Package = P2PConnector.Package<QRPackageDescription>
    typealias QRCodeImage = P2PConnector.QRCodeImage<QRPackageDescription>
    typealias QRCodeScanned = P2PConnector.QRCodeScanned<QRPackageDescription>
}

public struct QRCode<Description, Content> {
    public let description: Description
    public let content: Content
}
public typealias QRCodeImage<Description> = QRCode<Description, CGImage>
public typealias QRCodeScanned<Description> = QRCode<Description, String>
public typealias QRCodeParsed<Description> = QRCode<Description, Payload>

public final class QRCodeParser: QRCodeParserProtocol {

    private let jsonDecoder: JSONDecoder
    public init(jsonDecoder: JSONDecoder = .init()) {
        self.jsonDecoder = jsonDecoder
    }
}
public extension QRCodeParser {
    func parse<Description>(code: QRCodeScanned<Description>) async throws -> QRCodeParsed<Description> {
        let jsonData = code.content.data(using: .utf8)!
        let payload = try jsonDecoder.decode(Payload.self, from: jsonData)
        return QRCodeParsed.init(description: code.description, content: payload)
    }
}

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

private extension QRCodeTransport {
    
    func scan() async throws -> QRCodeScanned {
        try await qrCodeScanning.scan()
    }
    
    
    func transport<Content: Codable>(
        content: Content,
        type packageType: WebRTCPackageType,
        id: String = UUID().uuidString
    ) async throws {
        let packages: [Package] = try await packer.pack(content: content) { payload in
            QRPackageDescription(type: packageType, id: id)
        }
        
        let qrCodeImages: [QRCodeImage] = try await packages.asyncMap { package in
            let json = try jsonEncoder.encode(package)
            let image = try await qrCodeGenerator.generateQR(data: json)
            
            let qrCodeImage = QRCodeImage(
                description: package.packageDescription,
                content: image
            )
            
            return qrCodeImage
        }
        
        for qrCodeImage in qrCodeImages {
            try await qrCodeDisplaying.display(qrCodeImage: qrCodeImage)
        }
    }
    
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
            let scanned = try await scan()
            let parsed = try await qrCodeParser.parse(code: scanned)
            scannedContent += parsed.content.data
            isLast = parsed.content.payloadDescription.isLastPayloadForContent
            precondition(scannedContent.count == parsed.content.payloadDescription.totalPayloadCount)
        }
        
        let package = try JSONDecoder().decode(Package.self, from: scannedContent)

        guard package.packageDescription.packageType == packageType else {
            throw Error.expectedToScanQRCode(
                forType: packageType,
                butGot: package.packageDescription.packageType
            )
        }
        
        let payloadData = package.payload.data
        let content = try JSONDecoder().decode(Content.self, from: payloadData)
        return (content: content, payloadDescription: package.payload.payloadDescription, packageDescription: package.packageDescription)
    }
}

public extension QRCodeTransport {
    enum Error: Swift.Error {
        case expectedToScanQRCode(forType: WebRTCPackageType, butGot: WebRTCPackageType)
    }
}

public enum WebRTCPackageType: String, Equatable, Codable {
    case offer
    case answer
    case iceCandidate
}
