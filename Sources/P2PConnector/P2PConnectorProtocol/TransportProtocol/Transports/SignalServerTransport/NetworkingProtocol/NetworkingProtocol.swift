//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-29.
//

import Foundation

public protocol NetworkingProtocol {
    
    func connect() async
    
    /// Either websocket send or RESTFul POST/GET
    func send(data: Data) async throws
    
    /// Either a websocket subscription or poll based RESTFul request
    var incomingMessages: AsyncStream<Data> { get }
}
