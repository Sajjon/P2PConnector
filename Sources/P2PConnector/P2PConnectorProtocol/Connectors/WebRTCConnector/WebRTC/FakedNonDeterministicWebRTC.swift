//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-29.
//

import Foundation

public enum WebRTCEvent {
    case createdOffer(Offer)
    case generatedICECandidate(ICECandidate)
    case iceCandidateDidConnect(ICECandidate)
   
    case dataChannelDidOpen(P2PCommunicationChannel)
}
public extension WebRTCEvent {
    var offer: Offer? {
        switch self {
        case let .createdOffer(offer): return offer
        default: return nil
        }
    }
    
    var dataChannelDidOpen: P2PCommunicationChannel? {
        switch self {
        case let .dataChannelDidOpen(channel): return channel
        default: return nil
        }
    }
}

/// By non deterministic we mean that the order of events is unstructured, this WebRTC instance/client might
/// generate ICECandiates, then Offer, then ICECandidate. As per CAP-19, we would like it to be structured:
///
/// * Generate Offer
/// * Generate ICECandidates, batch thes by throttling.
public protocol NonDeterministicWebRTCProtocol {
    var unstructuredWebRTCEvents: AsyncStream<WebRTCEvent> { get}
    func createOfferAndUpdateInternalState() throws
    func setAnswer(answer: Answer) async throws
    func addRemoteICECandidate(_ iceCandidate: ICECandidate) async throws
}

public final class FakedNonDeterministicWebRTC: NonDeterministicWebRTCProtocol {
    public let unstructuredWebRTCEvents: AsyncStream<WebRTCEvent>

    private var iceCandidateIndex: Int32 = 0
    private var unstructuredWebRTCEventsContinuation: AsyncStream<WebRTCEvent>.Continuation
    
    private let interceptOutgoingP2PMessages: (Data) -> Void
    private var fakedIncomingMessagesContinuation: AsyncStream<Data>.Continuation
    private let fakedIncomingMessagesStream: AsyncStream<Data>
    
    public init(
        // For testing purposes
        interceptOutgoingP2PMessages: @escaping (Data) -> Void
    ) {
        
        self.interceptOutgoingP2PMessages = interceptOutgoingP2PMessages
        
        var continuation: AsyncStream<WebRTCEvent>.Continuation?
        let unstructuredWebRTCEvents = AsyncStream<WebRTCEvent> {
            continuation = $0
        }
        self.unstructuredWebRTCEvents = unstructuredWebRTCEvents
        self.unstructuredWebRTCEventsContinuation = continuation!
        
        var fakedIncomingMessagesContinuation: AsyncStream<Data>.Continuation?
        let fakedIncomingMessagesStream = AsyncStream<Data> { continuation in
            fakedIncomingMessagesContinuation = continuation
        }
        self.fakedIncomingMessagesStream = fakedIncomingMessagesStream
        self.fakedIncomingMessagesContinuation = fakedIncomingMessagesContinuation!
    }

    
}
public let minNumberOfCandidates: Int32 = 5
public let iceCandidateFromExtensionOffset: Int32 = 100
public extension FakedNonDeterministicWebRTC {
    
    func createOfferAndUpdateInternalState() throws {
        Task {
            try await Task.sleep(nanoseconds: 100_000_000)
            
            emitICECandidate()
            
            emit(
                event: .createdOffer(
                    Offer(sdp: "FAKE Offer from iOS")
                )
            )
            
            let randomNumberOfCandidates = Int.random(in: Int(minNumberOfCandidates-1)...20) // minus 1 since we sent one before offer above
            for _ in 0..<randomNumberOfCandidates {
                try await Task.sleep(nanoseconds: 10_000_000)
                emitICECandidate()
            }
        }
    }
    func setAnswer(answer: Answer) async throws {
        try await Task.sleep(nanoseconds: 30_000_000)
    }
    func addRemoteICECandidate(_ iceCandidate: ICECandidate) async throws {
        try await Task.sleep(nanoseconds: 30_000_000)
        let targetIndex = iceCandidateFromExtensionOffset + minNumberOfCandidates - 1
        if iceCandidate.lineIndex == targetIndex {
            emit(event: .iceCandidateDidConnect(iceCandidate))
           
            Task { [self] in
                try await Task.sleep(nanoseconds: 200_000_000)
                let channel = SimpleP2PChannel(incommingMessages: fakedIncomingMessagesStream) {
                    self.interceptOutgoingP2PMessages($0)
                    print("Faking sending: \(String(data: $0, encoding: .utf8)!)")
                }
                self.emit(event: .dataChannelDidOpen(channel))
                print("👻 Opened DATA Channel")
            }
           
        }
    }
}

public extension FakedNonDeterministicWebRTC {
    
    func fake(incomingMessageToChannel data: Data) {
        fakedIncomingMessagesContinuation.yield(data)
    }
}


private extension FakedNonDeterministicWebRTC {
    func emitICECandidate() {
        let fakeICE = ICECandidate(
            sdp: "FAKE ICECandiate from iOS",
            lineIndex: iceCandidateIndex
        )
        iceCandidateIndex += 1
        
        emit(event: .generatedICECandidate(fakeICE))
    }
    
    func emit(event: WebRTCEvent) {
        unstructuredWebRTCEventsContinuation.yield(event)
    }
}


public actor WrappedWebRTC: WebRTCProtocol {
    private let nonDeterministicWebRTC: NonDeterministicWebRTCProtocol
    private var cachedBatchedICECandidates: [ICECandidate] = []
    private var channelOpenedContinuation: AsyncStream<P2PCommunicationChannel>.Continuation?
    private let channelOpenedStream: AsyncStream<P2PCommunicationChannel>
    private var openChannel: P2PCommunicationChannel?
    public init(nonDeterministicWebRTC: NonDeterministicWebRTCProtocol) {
        self.nonDeterministicWebRTC = nonDeterministicWebRTC
        
        var channelOpenedContinuation: AsyncStream<P2PCommunicationChannel>.Continuation?
        let channelOpenedStream = AsyncStream<P2PCommunicationChannel> { continuation in
            channelOpenedContinuation = continuation
        }
        self.channelOpenedStream = channelOpenedStream
        self.channelOpenedContinuation = channelOpenedContinuation!
        
        Task {
            await handleIncomingEvents()
        }
    }
    
    private func handleIncomingEvents() {
        Task {
            for await event in self.nonDeterministicWebRTC.unstructuredWebRTCEvents {
                try await handleWebRTC(event: event)
            }
        }
    }
    private func handleWebRTC(event: WebRTCEvent) async throws {
        switch event {
        case .createdOffer:
            print("`createdOffer`, should have been handled in `createOffer()`")
            break
        case let .generatedICECandidate(iceCandidate):
            cachedBatchedICECandidates.append(iceCandidate)
        case .iceCandidateDidConnect:
            print("ICE candidate did connect!")
            break
        case let .dataChannelDidOpen(openChannel):
            self.openChannel = openChannel
            channelOpenedContinuation?.yield(openChannel)
        }
    }
}

public extension WrappedWebRTC {
    func createOffer() async throws -> Offer {
        try nonDeterministicWebRTC.createOfferAndUpdateInternalState()
        
        var createdOffer: Offer?
        for await offer in nonDeterministicWebRTC.unstructuredWebRTCEvents.compactMap({ $0.offer }).prefix(1) {
            createdOffer = offer
        }
        return createdOffer!
    }
    
    func iceCandidates(mode: GenerateICECandidatesMode) async throws -> [ICECandidate] {
        switch mode {
        case .asManyAsPossibleDuring(let durationInMilliseconds):
            let nanoseconds = UInt64(durationInMilliseconds * nanosecondsPerMillisecond)
            try await Task.sleep(nanoseconds: nanoseconds)
            return cachedBatchedICECandidates
        }
    }
    func setAnswerFromRemoteClient(_ answer: Answer) async throws {
        try await nonDeterministicWebRTC.setAnswer(answer: answer)
    }
    func setRemoteICECandidates(_ remoteICECandidates: [ICECandidate]) async throws {
        for remoteICE in remoteICECandidates {
            try await nonDeterministicWebRTC.addRemoteICECandidate(remoteICE)
        }
    }
    func channel() async throws -> P2PCommunicationChannel {
        if let openChannel = self.openChannel {
            return openChannel
        }
        var openedChannel: P2PCommunicationChannel?
        for await channel in channelOpenedStream.prefix(1) {
            openedChannel = channel
        }
        return openedChannel!
    }
}
