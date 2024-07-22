/// The states a WebSocketConnection can be in. These states are used by `RelaySubscriptionManager` to move each 
/// socket to the `connected` state where we can start executing requests, taking into account time to connect, errors
/// and authentication.
enum WebSocketState: Equatable {
    /// This socket is disconnected.
    case disconnected 
    
    /// The socket is in the process of connecting.
    case connecting
    
    /// The socket is connected and ready to receive requests.
    case connected 
    
    /// This socket has closed on an error. We record this and do exponential backoff before retrying.
    case errored(WebSocketErrorEvent)
}
