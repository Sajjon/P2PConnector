//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-28.
//

import Foundation

public actor WebRTCConnector: P2PConnectorProtocol {
    
    private let webRTC: WebRTCProtocol
    private let transport: TransportProtocol
    
    public init(
        webRTC: WebRTCProtocol,
        transport: TransportProtocol
    ) {
        self.webRTC = webRTC
        self.transport = transport
    }
}

public extension WebRTCConnector {
    func establishP2PConnection() async throws -> P2PCommunicationChannel {
        debugPrint("✨ Initializing transport")
        try await transport.initialize()
        debugPrint("☑️ Initialized transport")
        
        // Provide other client with webRTC "OFFER"
        debugPrint("🔮 Creating local OFFER")
        let offer = try await webRTC.createOffer()
        debugPrint("☑️ Created local OFFER")
        
        debugPrint("⬆️ Transporting local OFFER")
        try await transport.transport(offer: offer)
        debugPrint("☑️ Transported local OFFER")
        
        // Provide other client with webRTC "ICECandidates"
        let iceMode = GenerateICECandidatesMode.asManyAsPossibleDuring(durationInMilliseconds: 100)
        debugPrint("🔮 Generating local ICECANDIDATES, mode: \(iceMode)")
        let localICECandidates = try await webRTC.iceCandidates(
            mode: iceMode
        )
        debugPrint("☑️ Generated #\(localICECandidates.count) local ICECANDIDATES")

        debugPrint("⬆️ Transporting local ICECANDIDATES")
        try await transport.transport(iceCandidates: localICECandidates)
        debugPrint("☑️ Transported local ICECANDIDATES")
        
        debugPrint("⬇️ Fetching remote ANSWER")
        let answer = try await transport.fetchAnswer()
        debugPrint("☑️ Fetched remote ANSWER")
        
        debugPrint("🔮 Setting remote ANSWER")
        try await webRTC.setAnswerFromRemoteClient(answer)
        debugPrint("☑️ Set remote ANSWER")
        
        debugPrint("⬇️ Fetching remote ICECandidates")
        let remoteICECandidates = try await transport.fetchICECandidates()
        debugPrint("☑️ Fetched #\(remoteICECandidates.count) remote ICECANDIDATES\nRemote candidates:\n\(remoteICECandidates)\n\n")
        
        debugPrint("🔮 Setting remote ICECandidates")
        try await webRTC.setRemoteICECandidates(remoteICECandidates)
        debugPrint("☑️ Set remote ICECandidates")
        
        debugPrint("🔮 Waiting for WebRTC dataChannel to be opened.")
        let channel = try await webRTC.channel()
        debugPrint("✅ DataChannel is opened, P2P connection established. Good bye.")
        
        return channel
    }
}
