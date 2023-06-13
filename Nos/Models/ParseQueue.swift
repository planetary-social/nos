//
//  ParseQueue.swift
//  Nos
//
//  Created by Matthew Lorentz on 6/13/23.
//

import Foundation

/// An actor that queues up received Event JSON for parsing. 
actor ParseQueue {
    private var events = [JSONEvent]()
    
    func push(_ event: JSONEvent) {
        events.append(event)
    }
    
    func pop(_ count: Int) -> [JSONEvent] {
        let allEvents = Array(events.prefix(count))
        events.removeFirst(min(events.count, count))
        return allEvents
    }
}
