import SwiftUI

/// A view modifier that helps track when a tab becomes visible or invisible in a TabView.
struct OnTabAppearModifier: ViewModifier {
    @EnvironmentObject private var router: Router
    let tab: AppDestination
    let onAppear: (() async -> Void)?
    let onDisappear: (() async -> Void)?
    
    @State private var isVisible = false
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                if router.selectedTab == tab {
                    isVisible = true
                }
            }
            .onDisappear { isVisible = false }
            .onChange(of: isVisible) { 
                if isVisible {
                    Task { await onAppear?() }
                } else {
                    Task { await onDisappear?() }
                }
            }
    }
}

extension View {
    /// Executes an action when a specific tab becomes visible
    /// - Parameters:
    ///   - tab: The tab to monitor for visibility
    ///   - action: The action to perform when the tab becomes visible
    func onTabAppear(_ tab: AppDestination, perform action: @escaping () async -> Void) -> some View {
        modifier(OnTabAppearModifier(tab: tab, onAppear: action, onDisappear: nil))
    }

    /// Executes an action when a specific tab is navigated away from
    /// - Parameters:
    ///   - tab: The tab to monitor for visibility
    ///   - action: The action to perform when the tab becomes invisible
    func onTabDisappear(_ tab: AppDestination, perform action: @escaping () async -> Void) -> some View {
        modifier(OnTabAppearModifier(tab: tab, onAppear: nil, onDisappear: action))
    }
} 
