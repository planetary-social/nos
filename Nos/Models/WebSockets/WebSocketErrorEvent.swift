import Foundation

/// A container that tracks how many times we have tried unsuccessfully to open a websocket and the next time we should
/// try again.
struct WebSocketErrorEvent: Equatable {
    var retryCounter: Int = 1
    var nextRetry: Date = .now
    
    mutating func trackRetry() {
        self.retryCounter += 1
        let delaySeconds = NSDecimalNumber(
            decimal: pow(2, min(retryCounter, RelaySubscriptionManagerActor.maxBackoffPower))
        )
        self.nextRetry = Date(timeIntervalSince1970: Date.now.timeIntervalSince1970 + delaySeconds.doubleValue)
    }
}
