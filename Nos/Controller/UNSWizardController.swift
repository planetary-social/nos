//
//  UNSWizardController.swift
//  Nos
//
//  Created by Matthew Lorentz on 10/12/23.
//

import Foundation
import Dependencies

typealias UNSName = String

extension UNSName: Identifiable {
    public var id: String {
        self
    }
}

/// A controller for the Universal Name Wizard that walks a user through registering and linking a Universal Name to
/// their Nostr profile.
/// 
/// The controller keeps track of the user's place within the wizard using the `state` variable which is observed
/// by the `UNSWizard` view. It also holds some state like the current user information, names they have already 
/// registered, etc. 
class UNSWizardController: ObservableObject {
    enum FlowState {
        case loading
        case intro
        case enterPhone
        case enterOTP
        case newName
        case chooseName
        case success
        case error
        case nameTaken
        case needsPayment(URL)
    }
    
    @Published var state: FlowState
    @Published var authorKey: HexadecimalString?
    @Published var textField: String 
    @Published var phoneNumber: String?
    @Published var nameRecord: UNSNameRecord?
    
    /// All names the user has already registered
    @Published var names: [UNSNameRecord]?
    
    @Dependency(\.unsAPI) var api
    @Dependency(\.currentUser) var currentUser 
    @Dependency(\.analytics) var analytics
    
    internal init(
        state: UNSWizardController.FlowState = .intro, 
        authorKey: HexadecimalString? = nil, 
        textField: String = "", 
        phoneNumber: String? = nil, 
        nameRecord: UNSNameRecord? = nil, 
        names: [UNSNameRecord]? = nil
    ) {
        self.state = state
        self.authorKey = authorKey
        self.textField = textField
        self.phoneNumber = phoneNumber
        self.nameRecord = nameRecord
        self.names = names
    }
    
    func link(existingName: UNSNameRecord) async throws {
        nameRecord = existingName
        var nip05: String
        if let message = try await api.requestNostrVerification(
            npub: currentUser.keyPair!.npub,
            nameID: nameRecord!.id
        ) {
            nip05 = try await api.submitNostrVerification(
                message: message,
                keyPair: currentUser.keyPair!
            )
        } else {
            nip05 = try await api.getNIP05(for: nameRecord!.id)
        }
        try await saveDetails(name: existingName.name, nip05: nip05)
    }
    
    func register(desiredName: UNSName) async throws {
        state = .loading
        analytics.choseUNSName()
        do {
            let response = try await api.createName(
                // TODO: sanitize somewhere else
                desiredName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            ) 
            
            switch response {
            case.left(let nameID):
                nameRecord = UNSNameRecord(name: desiredName, id: nameID)
            case .right(let paymentURL):
                state = .needsPayment(paymentURL)
                return
            }
            let message = try await api.requestNostrVerification(
                npub: currentUser.keyPair!.npub, 
                nameID: nameRecord!.id
            )!
            let nip05 = try await api.submitNostrVerification(
                message: message,
                keyPair: currentUser.keyPair!
            )
            try await saveDetails(name: desiredName, nip05: nip05)
        } catch {
            if case let UNSError.requiresPayment(paymentURL) = error {
                print("go to \(paymentURL) to complete payment")
            } else {
                // TODO: show generic error message if the name isn't taken
                state = .nameTaken
                return
            }
        }
    }
    
    func navigateToChooseOrRegisterName() async throws {
        state = .loading
        let names = try await api.getNames()
        if !names.isEmpty {
            self.names = names
            state = .chooseName
        } else {
            state = .newName
        }
    }
    
    @MainActor func saveDetails(name: String, nip05: String) async throws {
        let author = currentUser.author
        author?.name = name
        author?.nip05 = nip05
        try currentUser.viewContext.save()
        await currentUser.publishMetaData()
        state = .success
    }
}

