//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-28.
//

import Foundation
import Combine
@testable import P2PConnector

public final class MockWebRTC: WebRTCProtocol {
    private let webRTCConfig: WebRTCConfig
    
//    private let channelSendSubject: PassthroughSubject<Data, Never>
//    private let channelMessagesPublisher: AnyPublisher<Data, Never>
//
//    private var cancellables = Set<AnyCancellable>()
    
//    private let _incommingMessages: AsyncStream<Data>
//    private let _sendData:  SimpleP2PChannel.SendData
    
    private let mockedP2PChannel: P2PCommunicationChannel
    
    init(
        webRTCConfig: WebRTCConfig,
//        channelSendSubject: PassthroughSubject<Data, Never>,
//        channelMessagesPublisher:  AnyPublisher<Data, Never>
//        incommingMessages: AsyncStream<Data>,
//        sendData: @escaping SimpleP2PChannel.SendData
        mockedP2PChannel: P2PCommunicationChannel
    ) {
        self.webRTCConfig = webRTCConfig
//        self.channelSendSubject = channelSendSubject
//        self.channelMessagesPublisher = channelMessagesPublisher
//        self._incommingMessages = incommingMessages
//        self._sendData = sendData
        self.mockedP2PChannel = mockedP2PChannel
    }
}

public extension MockWebRTC {
    func createOffer() async throws -> Offer {
        try await Task.sleep(nanoseconds: 10)
        return Offer(sdp: "mockedOfferFromiOS")
    }
    
    func iceCandidates(mode: GenerateICECandidatesMode) async throws -> [ICECandidate] {
        switch mode {
        case .asManyAsPossibleDuring(let durationInMilliseconds):
            let nanoseconds = UInt64(durationInMilliseconds * nanosecondsPerMillisecond)
            try await Task.sleep(nanoseconds: nanoseconds)
            return [0, 1, 2, 3].map { ICECandidate.init(sdp: "mockCandidateFromiOS", lineIndex: $0) }
        }
    }
    
    func setAnswerFromRemoteClient(_ answer: Answer) async throws {
        try await Task.sleep(nanoseconds: 10)
    }
    
    func setRemoteICECandidates(_ remoteICECandidates: [ICECandidate]) async throws {
        try await Task.sleep(nanoseconds: 10)
    }
    
    func channel() async throws -> P2PCommunicationChannel {
        try await Task.sleep(nanoseconds: 10)
//        return SimpleP2PChannel(
//            incommingMessages: _incommingMessages,
//            sendData: _sendData
//        )
        return mockedP2PChannel
    }
}
