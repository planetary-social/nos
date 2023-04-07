//
//  AsyncTimer.swift
//  Nos
//
//  Created by Matthew Lorentz on 4/7/23.
//

import Foundation

/// A timer that executes a task on a schedule. Similar to NSTimer but works with Swift Structured Concurrency.
class AsyncTimer {
    
    private var task: Task<Void, Never>
    
    init(timeInterval: TimeInterval, priority: TaskPriority = .utility, onFire: @escaping () async -> Void) {
        self.task = Task(priority: priority) {
            while !Task.isCancelled {
                await onFire()
                try? await Task.sleep(nanoseconds: UInt64(timeInterval * 1_000_000_000))
            }
        }
    }
    
    func cancel() {
        task.cancel()
    }
}
