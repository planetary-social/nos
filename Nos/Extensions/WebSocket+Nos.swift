//
//  WebSocket+Nos.swift
//  Nos
//
//  Created by Matthew Lorentz on 4/7/23.
//

import Foundation
import Starscream

extension WebSocket {
    var host: String {
        self.request.url?.host ?? "unknown relay"
    }
    
    var url: URL? {
        self.request.url
    }
}

extension WebSocketClient {
    var host: String {
        (self as? WebSocket)?.host ?? "unkown relay"
    }
    
    var url: URL? {
        (self as? WebSocket)?.url
    }
}
