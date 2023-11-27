//
//  DoubleTapToPopModifier.swift
//  Nos
//
//  Created by Martin Dutra on 21/8/23.
//

import Combine
import SwiftUI

/// Detects double taps on a tab item and pops the opened screens to return the user to the root view
struct DoubleTapToPopModifier: ViewModifier {

    var tab: AppDestination
    var onRoot: (@MainActor () -> Void)?

    @Environment(Router.self) private var router
    @State private var cancellable: AnyCancellable?

    func body(content: Content) -> some View {
        content
            .onChange(of: router.selectedTab, { oldValue, newValue in
                if oldValue != newValue {
                    let path = router.path(for: tab)
                    if path.wrappedValue.isEmpty {
                        if let onRoot {
                            onRoot()
                        }
                    } else {
                        router.currentPath.wrappedValue.removeLast(router.currentPath.wrappedValue.count)
                    }
                }
            })
    }
}

extension View {
    func doubleTapToPop(tab: AppDestination, onRoot: (@MainActor () -> Void)? = nil) -> some View {
        self.modifier(DoubleTapToPopModifier(tab: tab, onRoot: onRoot))
    }
}
