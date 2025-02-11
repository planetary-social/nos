import Foundation

/// Defines a common interface for refreshing.
@Observable @MainActor final class RefreshController {
    /// Whether a refresh should start or not. When this is `true`, the view and data source will begin refreshing.
    var startRefresh: Bool

    /// The last time the view was refreshed.
    var lastRefreshDate: Date
    
    /// Initializes a refresh controller with the given parameters.
    /// - Parameters:
    ///   - startRefresh: Whether a refresh should start or not. Defaults to `false`.
    ///   - lastRefreshDate: The last time the view was refreshed. Defaults to `.now`.
    init(startRefresh: Bool = false, lastRefreshDate: Date = .now) {
        self.startRefresh = startRefresh
        self.lastRefreshDate = lastRefreshDate
    }
}
