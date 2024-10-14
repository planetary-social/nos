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
