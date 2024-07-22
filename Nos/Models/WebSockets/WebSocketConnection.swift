import Starscream

/// Represents a connection to a websocket with state tracking. Utilizes a Starscream WebSocket under the hood.
class WebSocketConnection {
    let socket: WebSocket
    var state: WebSocketState 
    
    init(socket: WebSocket, state: WebSocketState = .disconnected) {
        self.socket = socket
        self.state = state
    }
}
