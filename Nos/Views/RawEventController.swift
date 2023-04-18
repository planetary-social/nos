//
//  RawEventController.swift
//  Planetary
//
//  Created by Martin Dutra on 19/9/22.
//  Copyright © 2022 Verse Communications Inc. All rights reserved.
//

import Foundation
import Logger

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
        loadingMessage = Localized.loading.string
        Task.detached { [note, weak self] in
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
            await self?.updateRawMessage(rawMessage)
        }
    }
}
