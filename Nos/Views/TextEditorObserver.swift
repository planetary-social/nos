//
//  TextEditorObserver.swift
//  Nos
//
//  Created by Martin Dutra on 3/4/23.
//

import Combine
import Foundation
import SwiftUI

/// This class is suited to be used in a TextEditor as it throttles the text into throttledText
class TextEditorObserver: ObservableObject {
    @Published
    var throttledText = ""

    @Published
    var text = ""

    private var subscriptions = Set<AnyCancellable>()

    init() {
        $text
            .removeDuplicates()
            .throttle(for: .seconds(2), scheduler: RunLoop.main, latest: true)
            .sink { [weak self] value in
                self?.throttledText = value
            }
            .store(in: &subscriptions)
    }
}
