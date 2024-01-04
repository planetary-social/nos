//
//  RawEventController.swift
//  Planetary
//
//  Created by Martin Dutra on 19/9/22.
//  Copyright © 2022 Verse Communications Inc. All rights reserved.
//

import Foundation
import Logger

/// A view model for the RawEventView
@MainActor protocol RawEventViewModel: ObservableObject {
    
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
@MainActor class RawEventController: RawEventViewModel {

    private var note: Event

    @Published var rawMessage: String?
    
    @Published var loadingMessage: String?

    @Published var errorMessage: String?
    
    private var dismissHandler: () -> Void

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

    private func updateErrorMessage(_ errorMessage: String) {
        self.errorMessage = errorMessage
        self.loadingMessage = nil
    }

    private func loadRawMessage() {
        loadingMessage = String(localized: .localizable.loading)
        Task { [note, weak self] in
            var rawMessage: String
            let errorMessage = note.content ?? "error"
            do {
                let data = try JSONSerialization.data(
                    withJSONObject: note.jsonRepresentation ?? [:],
                    options: [.prettyPrinted]
                )
                rawMessage = String(data: data, encoding: .utf8) ?? errorMessage
            } catch {
                rawMessage = errorMessage
            }
            self?.updateRawMessage(rawMessage)
        }
    }
}
