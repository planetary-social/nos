import Foundation

/// A refresh controller used for testing.
class MockRefreshController: RefreshController {
    var isRefreshing = false
    var lastRefreshDate: Date?

    func beginRefreshing() {
    }
    
    func endRefreshing() {
    }

    func setLastRefreshDate(_ lastRefreshDate: Date) {
    }
}
