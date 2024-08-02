import Foundation

/// Defines a common interface for refreshing.
@MainActor protocol RefreshController: Observable {
    /// Whether the `RefreshController` is currently refreshing.
    var isRefreshing: Bool { get }

    /// The last time the view was refreshed.
    var lastRefreshDate: Date? { get }

    /// Start refreshing.
    func beginRefreshing()

    /// End refreshing.
    func endRefreshing()

    /// Updates the last refresh date to the given value.
    func setLastRefreshDate(_: Date)
}

/// The default implementation of `RefreshController`.
@Observable @MainActor class DefaultRefreshController: RefreshController {
    var isRefreshing: Bool

    var lastRefreshDate: Date?

    init(isRefreshing: Bool = false, lastRefreshDate: Date? = nil) {
        self.isRefreshing = isRefreshing
    }

    func beginRefreshing() {
        isRefreshing = true
    }

    func endRefreshing() {
        isRefreshing = false
    }

    func setLastRefreshDate(_ lastRefreshDate: Date) {
        self.lastRefreshDate = lastRefreshDate
    }
}
