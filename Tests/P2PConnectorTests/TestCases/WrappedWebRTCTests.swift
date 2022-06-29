//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-29.
//

import Foundation
import XCTest
@testable import P2PConnector

final class WrappedWebRTCTests: XCTestCase {
    func test_WrappedWebRTC() async throws {
        var interceptedMessagesToBrowser = [Data]()
        var signalServerTransportSentMessage = [(ConnectionID, Data)]()
        let fakedWebRTC = FakedNonDeterministicWebRTC {
            interceptedMessagesToBrowser.append($0)
        }
        let wrappedWebRTC = WrappedWebRTC(nonDeterministicWebRTC: fakedWebRTC)
        
        let mockedEncryption = MockEncryption(
            encrypt: { $0 },
            decrypt: { $0}
        )
        
        let mockedSignalServer = MockSignalServerTransport(
            connectionID: "deadbeef",
            encryption: mockedEncryption,
            sendData: { connectionID, data in
                signalServerTransportSentMessage.append((connectionID, data))
            },
            fetchData: { _ in Data() /* empty dummy data */ }
        )
        
        let connector = WebRTCConnector(webRTC: wrappedWebRTC, transport: mockedSignalServer)
        
        let channel = try await connector.establishP2PConnection()
        
        let messageToBrowser = "Hey Browser this is iOS".data(using: .utf8)!
        try await channel.send(data: messageToBrowser)
        XCTAssertEqual(interceptedMessagesToBrowser, [messageToBrowser])
        let mesesageFromBrower = "Hey iOS this is Browser".data(using: .utf8)!
        fakedWebRTC.fake(incomingMessageToChannel: mesesageFromBrower)
        for await messageToMobile in channel.incommingMessages.prefix(1) {
            XCTAssertEqual(messageToMobile, mesesageFromBrower)
        }
    }
}
