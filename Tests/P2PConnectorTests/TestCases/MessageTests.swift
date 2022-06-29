//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-29.
//

import Foundation
import XCTest
@testable import P2PConnector

extension String {
    var data: Data {
        self.data(using: .utf8)!
    }
}
extension Data {
    var jsonString: String {
        return String(
            data: self,
            encoding: .utf8
        )!
    }
}

public enum Client: String, Codable {
    case mobile
    case browserExtension
}

public protocol WebRTCContentType: Codable {
    static var offer: Self { get }
    static var answer: Self { get }
    static var iceCandidate: Self { get }
}

public protocol WebRTCTransportMessage: Codable {
    associatedtype ContentType: WebRTCContentType
    associatedtype Payload

    var contentType: ContentType { get }
    var source: Client { get }
    var messageID: String { get }
    
    var payload: Payload? { get }
}

public enum WebRTCSignalServerTransportContentType: String, WebRTCContentType {
    case offer
    case answer
    case iceCandidate
    case subscribe
}

public typealias EnryptedData = Data

public struct WebRTCSignalServerTransportMessage: WebRTCTransportMessage {
   
    public let contentType: WebRTCSignalServerTransportContentType
    public let source: Client
    public let messageID: String
    public let connectionID: String
    
    // Nil for `subscribe`
    public let payload: EnryptedData?
}

final class MessageTests: XCTestCase {
    
    func test_decode_WebRTCSignalServerTransportMessage_Answer() throws {
        let json =
"""
{
    "connectionID": "fadedeaf",
    "contentType": "answer",
    "messageID": "1234",
    "payload": "deadbeef",
    "source": "mobile"
}
"""
        let message = try JSONDecoder.hex.decode(
            WebRTCSignalServerTransportMessage.self,
            from: json.data
        )
        
        XCTAssertEqual(message.messageID, "1234")
        XCTAssertEqual(message.contentType, .answer)
        XCTAssertEqual(message.source, .mobile)
        XCTAssertEqual(message.connectionID, "fadedeaf")
        XCTAssertEqual(message.payload?.hexEncodedString(), "deadbeef")
    }
    
    func test_decode_WebRTCSignalServerTransportMessage_Subscribe() throws {
        let json =
"""
{
    "connectionID": "fadedeaf",
    "contentType": "subscribe",
    "messageID": "1234",
    "source": "mobile"
}
"""
        let message = try JSONDecoder.hex.decode(
            WebRTCSignalServerTransportMessage.self,
            from: json.data
        )
        
        XCTAssertEqual(message.messageID, "1234")
        XCTAssertEqual(message.contentType, .subscribe)
        XCTAssertEqual(message.source, .mobile)
        XCTAssertEqual(message.connectionID, "fadedeaf")
        XCTAssertNil(message.payload)
        
        let jsonData = try JSONEncoder.hex.encode(message)
        
        XCTAssertEqual(
            jsonData.jsonString.trimmed,
            json.trimmed
        )
    }
}

extension String {
    var trimmed: Self {
        func doTrim(s: String) -> String {
            s
                .replacingOccurrences(of: " \"", with: "\"")
            
        }
        var _trimmed = self.replacingOccurrences(of: "\" : \"", with: "\": \"")
        while true {
            let trimmed = doTrim(s: _trimmed)
            if trimmed == _trimmed {
                break
            } else {
                _trimmed = trimmed
            }
        }
        return _trimmed
    }
}
