I've made this in my free time, it contains some sketches for a highly abstracted WebRTC Swift solution, which uses an abstraction of "Transport Layer".

Take a look at file `WebRTCConnector`

```swift

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
        try await transport.initialize()
        
        // Provide other client with webRTC "OFFER"
        let offer = try await webRTC.createOffer()
        
        try await transport.transport(offer: offer)
        
        // Provide other client with webRTC "ICECandidates"
        let iceMode = GenerateICECandidatesMode.asManyAsPossibleDuring(durationInMilliseconds: 100)
        let localICECandidates = try await webRTC.iceCandidates(
            mode: iceMode
        )

        try await transport.transport(iceCandidates: localICECandidates)
        
        let answer = try await transport.fetchAnswer()
        
        try await webRTC.setAnswerFromRemoteClient(answer)
        
        let remoteICECandidates = try await transport.fetchICECandidates()
        
        try await webRTC.setRemoteICECandidates(remoteICECandidates)
        
        let channel = try await webRTC.channel()
        
        return channel
    }
}

```

I am fairly confident that we can get this clean code!!

I've completely messed up the Message format of TransportProtocols though. So please feel free to scratch that.