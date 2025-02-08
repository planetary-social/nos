import Foundation

/// A timer that executes a task on a schedule. Similar to NSTimer but works with Swift Structured Concurrency.
final class AsyncTimer {
    
    private let task: Task<Void, Never>
    
    init(
        timeInterval: TimeInterval, 
        priority: TaskPriority = .utility, 
        firesImmediately: Bool = true, 
        onFire: @escaping () async -> Void
    ) {
        task = Task(priority: priority) {
            if !firesImmediately {
                try? await Task.sleep(nanoseconds: UInt64(timeInterval * 1_000_000_000))
            }

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
