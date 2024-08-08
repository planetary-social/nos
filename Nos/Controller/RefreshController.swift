import Foundation

/// The default implementation of `RefreshController`.
@Observable @MainActor class RefreshController {
    /// Whether a refresh should begin or not.
    var shouldRefresh: Bool

    /// The last time the view was refreshed.
    var lastRefreshDate: Date
    
    /// Initializes a refresh controller with the given parameters.
    /// - Parameters:
    ///   - shouldRefresh: Whether a refresh should begin or not. Defaults to `false`.
    ///   - lastRefreshDate: The last time the view was refreshed. Defaults to `.now`.
    init(shouldRefresh: Bool = false, lastRefreshDate: Date = .now) {
        self.shouldRefresh = shouldRefresh
        self.lastRefreshDate = lastRefreshDate
    }
}
