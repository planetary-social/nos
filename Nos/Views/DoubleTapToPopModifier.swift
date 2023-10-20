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

    @EnvironmentObject private var router: Router
    @State private var cancellable: AnyCancellable?

    func body(content: Content) -> some View {
        content.task {
            if cancellable == nil {
                cancellable = router.consecutiveTaps(on: tab)
                    .sink {
                        let path = router.path(for: tab)
                        if !path.wrappedValue.isEmpty {
                            path.wrappedValue.removeLast(path.wrappedValue.count)
                        }
                    }
            }
        }
    }
}

extension View {
    func doubleTapToPop(tab: AppDestination) -> some View {
        self.modifier(DoubleTapToPopModifier(tab: tab))
    }
}
