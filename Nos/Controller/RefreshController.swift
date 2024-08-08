import Foundation

/// Defines a common interface for refreshing.
@MainActor protocol RefreshController: Observable {
    /// Whether a refresh should begin or not.
    var shouldRefresh: Bool { get set }

    /// The last time the view was refreshed.
    var lastRefreshDate: Date { get set }
}

/// The default implementation of `RefreshController`.
@Observable @MainActor class DefaultRefreshController: RefreshController {
    var shouldRefresh: Bool
    var lastRefreshDate: Date

    init(shouldRefresh: Bool = false, lastRefreshDate: Date = .now) {
        self.shouldRefresh = shouldRefresh
        self.lastRefreshDate = lastRefreshDate
    }
}
