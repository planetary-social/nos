import Combine
import Foundation
import SwiftUI

/// Class suitable for being used in a searchable modifier as it debounces
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
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.debouncedText = value
            }
            .store(in: &subscriptions)
    }
}
