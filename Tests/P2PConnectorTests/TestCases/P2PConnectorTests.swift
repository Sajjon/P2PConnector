import XCTest
import Combine
@testable import P2PConnector

final class MockedP2PChannel: P2PCommunicationChannel {
   
    private let incomingMessagesContinuation: AsyncStream<Data>.Continuation
    private let outgoingMessagesContinuation: AsyncStream<Data>.Continuation
    
 
    internal let incommingMessages: AsyncStream<Data>
    internal let outgoingMessages: AsyncStream<Data>
    
    init() {
        var incomingMessagesContinuation: AsyncStream<Data>.Continuation?
        let incomingMessagesStream = AsyncStream<Data>.init { continuation in
            incomingMessagesContinuation = continuation
        }
        
        var outgoingMessagesContinuation: AsyncStream<Data>.Continuation?
        let outgoingMessagesStream = AsyncStream<Data>.init { continuation in
            outgoingMessagesContinuation = continuation
        }
        
        self.incomingMessagesContinuation = incomingMessagesContinuation!
        self.outgoingMessagesContinuation = outgoingMessagesContinuation!
      
        self.incommingMessages = incomingMessagesStream
        self.outgoingMessages = outgoingMessagesStream
    }
    
    internal func send(data: Data) async throws {
        outgoingMessagesContinuation.yield(data)
    }
    
    func mockIncoming(message: Data) {
        incomingMessagesContinuation.yield(message)
    }
}

final class P2PConnectorTests: XCTestCase {
    func testMockedWebRTCConnector() async throws {
        let mockedEncryption = MockEncryption(
            encrypt: { $0 },
            decrypt: { $0}
        )
        
        let mockedSignalServer = MockSignalServerTransport(
            connectionID: "deadbeef",
            encryption: mockedEncryption,
            sendData: { _, _ in /* ignored */ },
            fetchData: { _ in Data() /* empty dummy data */ }
        )
        
        let mockP2PChannel = MockedP2PChannel()
        
        let mockedWebRTC = MockWebRTC(
            webRTCConfig: WebRTCConfig.default,
            mockedP2PChannel: mockP2PChannel
        )
        
        let signalServerWebRTCConnector: P2PConnectorProtocol = WebRTCConnector(
            webRTC: mockedWebRTC,
            transport: mockedSignalServer
        )
        
        let p2pCommunicationChannel: P2PCommunicationChannel = try await signalServerWebRTCConnector.establishP2PConnection()
        
        
        try await p2pCommunicationChannel.send(data: Data([0xde, 0xad, 0xbe, 0xef]))
        for await message in mockP2PChannel.outgoingMessages.prefix(1) {
            XCTAssertEqual(message, Data([0xde, 0xad, 0xbe, 0xef]))
        }
    
        mockP2PChannel.mockIncoming(message: Data([0xfa, 0xde]))
        for await message in p2pCommunicationChannel.incommingMessages.prefix(1) {
            XCTAssertEqual(message, Data([0xfa, 0xde]))
        }
    }
}
