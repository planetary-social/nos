import Foundation

/// Defines a common interface for refreshing.
@MainActor protocol RefreshController: Observable {
    /// Whether a refresh should begin or not.
    var shouldRefresh: Bool { get }

    /// The last time the view was refreshed.
    var lastRefreshDate: Date? { get }

    /// Update the state of `shouldRefresh` to the given value.
    func setShouldRefresh(_: Bool)

    /// Updates the last refresh date to the given value.
    func setLastRefreshDate(_: Date)
}

/// The default implementation of `RefreshController`.
@Observable @MainActor class DefaultRefreshController: RefreshController {
    var shouldRefresh: Bool

    var lastRefreshDate: Date?

    init(shouldRefresh: Bool = false, lastRefreshDate: Date? = nil) {
        self.shouldRefresh = shouldRefresh
        self.lastRefreshDate = lastRefreshDate
    }

    func setShouldRefresh(_ shouldRefresh: Bool) {
        self.shouldRefresh = shouldRefresh
    }

    func setLastRefreshDate(_ lastRefreshDate: Date) {
        self.lastRefreshDate = lastRefreshDate
    }
}
