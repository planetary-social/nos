import Combine
import SwiftUI

@Observable final class TextDebouncer {

    private(set) var debouncedText = ""

    var text = "" {
        didSet {
            textPublisher.send(text)
        }
    }
    @ObservationIgnored private lazy var textPublisher = CurrentValueSubject<String, Never>(text)

    private var subscriptions = Set<AnyCancellable>()

    init() {
        textPublisher
            .removeDuplicates()
            .filter { $0.count >= 3 }
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.debouncedText = value
            }
            .store(in: &subscriptions)
    }
}
