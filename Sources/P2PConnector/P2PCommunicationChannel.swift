//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-06-28.
//

import Foundation

public protocol P2PCommunicationChannel {
    func send(data: Data) async throws
    var incommingMessages: AsyncStream<Data> { get }
}
