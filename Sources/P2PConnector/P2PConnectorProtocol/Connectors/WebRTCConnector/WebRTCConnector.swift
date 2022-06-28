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
       
        // Provide other client with webRTC "OFFER"
        let offer = try await webRTC.createOffer()
        try await transport.transport(offer: offer)
        
        // Provide other client with webRTC "ICECandidates"
        let localICECandidates = try await webRTC.iceCandidates(
            mode: .asManyAsPossibleDuring(durationInMilliseconds: 100)
        )
        try await transport.transport(iceCandidates: localICECandidates)
        
        let answer = try await transport.fetchAnswer()
        try await webRTC.setAnswerFromRemoteClient(answer)
        
        let remoteICECandidates = try await transport.fetchICECandidates()
        try await webRTC.setRemoteICECandidates(remoteICECandidates)
        
        return try await webRTC.channel()
    }
}
