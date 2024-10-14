import DequeModule
import Foundation
import Starscream

/// An actor that queues up received Event JSON for parsing.
actor ParseQueue {
    private var events = Deque<(JSONEvent, WebSocket)>()

    func push(_ event: JSONEvent, from socket: WebSocket) {
        events.append((event, socket))
    }

    func pop(_ count: Int) -> [(JSONEvent, WebSocket)] {
        let poppedEvents = Array(events.prefix(count))
        events.removeFirst(min(events.count, count))
        return poppedEvents
    }

    var count: Int {
        events.count
    }
}
