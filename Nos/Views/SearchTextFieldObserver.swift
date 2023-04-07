//
//  SearchTextFieldObserver.swift
//  Nos
//
//  Created by Martin Dutra on 3/4/23.
//

import Combine
import Foundation
import SwiftUI

/// Class suitable for being used ina searchable modifier as it debounces
/// the input to debouncedText.
class SearchTextFieldObserver: ObservableObject {
    @Published
    var debouncedText = ""

    @Published
    var text = ""

    private var subscriptions = Set<AnyCancellable>()

    init() {
        $text
            .removeDuplicates()
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.debouncedText = value
            }
            .store(in: &subscriptions)
    }
}
