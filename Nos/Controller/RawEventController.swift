import Foundation
import Logger

/// A view model for the RawEventView
protocol RawEventViewModel {
    
    /// The raw message to display in screen
    var rawMessage: String? { get }
    
    /// A loading message that should be displayed when it is not nil
    var loadingMessage: String? { get }
    
    /// An error message that should be displayed when it is not nil
    var errorMessage: String? { get }
    
    /// Called when the user dismisses the shown error message. Should clear `errorMessage`.
    func didDismissError()
    
    /// Called when the user taps on the Cancel button
    func didDismiss()
}

/// A controller for the `RawEventView`
@Observable final class RawEventController: RawEventViewModel {

    private let note: Event
    private let dismissHandler: () -> Void

    private(set) var rawMessage: String?
    private(set) var loadingMessage: String?
    private(set) var errorMessage: String?

    init(note: Event, dismissHandler: @escaping () -> Void) {
        self.note = note
        self.dismissHandler = dismissHandler
        loadRawMessage()
    }

    func didDismissError() {
        errorMessage = nil
        didDismiss()
    }
    
    func didDismiss() {
        dismissHandler()
    }

    private func updateRawMessage(_ rawMessage: String) {
        self.rawMessage = rawMessage
        self.loadingMessage = nil
    }
    
    private func loadRawMessage() {
        loadingMessage = String(localized: "loading")
        
        let rawMessage: String
        do {
            let data = try JSONSerialization.data(
                withJSONObject: note.jsonRepresentation ?? [:],
                options: [.prettyPrinted]
            )
            rawMessage = String(decoding: data, as: UTF8.self)
        } catch {
            rawMessage = note.content ?? "error"
        }
        updateRawMessage(rawMessage)
    }
}
