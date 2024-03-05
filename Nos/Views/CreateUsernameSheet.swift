//
//  CreateUsernameSheet.swift
//  Nos
//
//  Created by Martin Dutra on 31/1/24.
//

import Combine
import Dependencies
import Logger
import SwiftUI

struct CreateUsernameSheet: View {

    @Binding var isPresented: Bool

    @Dependency(\.analytics) private var analytics

    var body: some View {
        NavigationStack {
            ClaimYourUniqueIdentityPage(isPresented: $isPresented)
        }
        .frame(idealWidth: 320, idealHeight: 480)
        .presentationDetents([.medium])
        .onAppear {
            analytics.showedNIP05Wizard()
        }
    }
}

fileprivate class UsernameObserver: ObservableObject {

    @Published
    var debouncedText = ""

    @Published
    var text = ""

    private var subscriptions = Set<AnyCancellable>()

    init() {
        $text
            .removeDuplicates()
            .filter { $0.count >= 3 }
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.debouncedText = value
            }
            .store(in: &subscriptions)
    }
}

fileprivate struct ClaimYourUniqueIdentityPage: View {

    @Binding var isPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer(minLength: 40)
            PlainText(String(localized: LocalizedStringResource.localizable.new).uppercased())
                .padding(.horizontal, 6)
                .padding(.vertical, 5)
                .font(.clarity(.bold, textStyle: .footnote))
                .foregroundStyle(Color.white)
                .background {
                    Color.secondaryTxt
                        .cornerRadius(4, corners: .allCorners)
                }
            PlainText(.localizable.claimUniqueUsernameTitle).profileEditSheetTitle()
            PlainText(.localizable.claimUniqueUsernameDescription).profileEditSheetDescription()

            Spacer(minLength: 0)

            NavigationLink(String(localized: LocalizedStringResource.localizable.setUpMyUsername)) {
                PickYourUsernamePage(isPresented: $isPresented)
            }
            .buttonStyle(BigActionButtonStyle())

            Spacer(minLength: 40)
        }
        .padding(.horizontal, 40)
        .profileEditSheetPage()
    }
}

fileprivate struct PickYourUsernamePage: View {

    @Binding var isPresented: Bool
    @StateObject private var usernameObserver = UsernameObserver()
    @State private var verified: Bool?
    @State private var isVerifying = false
    @Dependency(\.namesAPI) var namesAPI
    @Dependency(\.currentUser) var currentUser

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Button {
                isPresented = false
            } label: {
                PlainText(.localizable.cancel)
                    .font(.clarity(.medium, textStyle: .body))
                    .foregroundStyle(Color.primaryTxt)
                    .padding()
            }
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    PlainText(.localizable.pickYourUsernameTitle).profileEditSheetTitle()
                    PlainText(.localizable.pickYourUsernameDescription).profileEditSheetDescription()
                    HStack {
                        UsernameTextField(usernameObserver: usernameObserver)
                            .onChange(of: usernameObserver.debouncedText) { _, newValue in
                                Task {
                                    await verify(newValue)
                                }
                            }
                            .onSubmit {
                                Task {
                                    await verify(usernameObserver.text)
                                }
                            }
                        PlainText(".nos.social")
                            .font(.clarityTitle3)
                            .foregroundStyle(Color.secondaryTxt)
                    }
                    if validationFailed {
                        usernameAlreadyClaimedText()
                    } else {
                        usernameAlreadyClaimedText()
                            .hidden()
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 40)

                NavigationLink {
                    ExcellentChoicePage(username: usernameObserver.text, isPresented: $isPresented)
                } label: {
                    if isVerifying {
                        ZStack {
                            ProgressView()
                                .frame(height: .zero)
                                .tint(Color.white)
                            PlainText(.localizable.next)
                                .hidden()
                        }
                    } else {
                        PlainText(.localizable.next)
                    }
                }
                .padding(.horizontal, 40)
                .buttonStyle(BigActionButtonStyle())
                .disabled(verified != true || isVerifying || invalidInput)
            }
        }
        .profileEditSheetPage()
    }

    private func usernameAlreadyClaimedText() -> some View {
        PlainText(.localizable.usernameAlreadyClaimed)
            .font(.clarity(.medium, textStyle: .subheadline))
            .foregroundStyle(Color.red)
            .lineSpacing(3)
    }

    private var invalidInput: Bool {
        usernameObserver.text.count < 3
    }

    private var validationFailed: Bool {
        verified == false
    }

    private func verify(_ username: String) async {
        verified = nil

        guard !username.isEmpty, let keyPair = currentUser.keyPair else {
            return
        }

        isVerifying = true

        defer {
            isVerifying = false
        }

        do {
            verified = try await namesAPI.verify(username: username, keyPair: keyPair)
        } catch {
            Log.error(error.localizedDescription)
        }
    }
}

fileprivate struct UsernameTextField: View {

    @StateObject var usernameObserver: UsernameObserver
    @FocusState private var usernameFieldIsFocused: Bool

    var body: some View {
        SwiftUI.TextField(
            text: $usernameObserver.text,
            prompt: PlainText(.localizable.username).foregroundStyle(Color.secondaryTxt)
        ) {
            PlainText(.localizable.username)
                .foregroundStyle(Color.primaryTxt)
        }
        .focused($usernameFieldIsFocused)
        .font(.clarity(.bold, textStyle: .title3))
        .textInputAutocapitalization(.never)
        .textCase(.lowercase)
        .autocorrectionDisabled()
        .foregroundStyle(Color.primaryTxt)
        .lineLimit(1)
        .padding(10)
        .cornerRadius(10)
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondaryTxt, lineWidth: 2)
        }
        .background {
            Color.black.opacity(0.1).cornerRadius(10)
        }
        .onChange(of: usernameObserver.text) { oldValue, newValue in
            let characterset = CharacterSet(
                charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-."
            )
            if newValue.rangeOfCharacter(from: characterset.inverted) != nil {
                usernameObserver.text = oldValue
            } else if newValue.count > 30 {
                usernameObserver.text = oldValue
            } else {
                usernameObserver.text = newValue.lowercased()
            }
        }
    }
}

fileprivate struct ExcellentChoicePage: View {

    var username: String
    @Binding var isPresented: Bool

    @State private var claimState: ClaimState = .idle
    @Dependency(\.currentUser) private var currentUser
    @Dependency(\.namesAPI) private var namesAPI
    @Dependency(\.analytics) private var analytics

    /// The current state of the claim request.
    private enum ClaimState {
        /// There is no request in progress yet
        case idle

        /// The request is in progress
        case claiming

        /// The request finished successfully
        case claimed

        /// Something was wrong with the request
        case failed(ClaimError)

        var hasError: Bool {
            error != nil
        }

        var error: ClaimError? {
            switch self {
            case .failed(let error):
                return error
            default:
                return nil
            }
        }
    }

    private var attributedUsername: AttributedString {
        AttributedString(
            username,
            attributes: AttributeContainer([NSAttributedString.Key.foregroundColor: UIColor(Color.primaryTxt)])
        ) + AttributedString(".nos.social")
    }

    private var showAlert: Binding<Bool> {
        Binding {
            claimState.hasError
        } set: { _ in
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer(minLength: 40)
            switch claimState {
            case .idle, .claiming:
                ProgressView()
                    .tint(Color.accentColor)
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed(let error):
                SwiftUI.Text(error.localizedDescription)
                    .font(.clarity(.regular, textStyle: .callout))
                    .foregroundStyle(Color.primaryTxt)
            case .claimed:
                PlainText(.localizable.excellentChoice).profileEditSheetTitle()
                SwiftUI.Text(attributedUsername)
                    .font(.clarity(.bold, textStyle: .title3))
                    .foregroundStyle(Color.secondaryTxt)
                SwiftUI.Text(
                    LocalizedStringKey(
                        String(localized: LocalizedStringResource.localizable.usernameClaimedNotice(username))
                    )
                )
                .profileEditSheetDescription()

                Spacer(minLength: 0)

                Button(String(localized: LocalizedStringResource.localizable.done)) {
                    isPresented = false
                }
                .buttonStyle(BigActionButtonStyle())
            }
            Spacer(minLength: 40)
        }
        .frame(maxWidth: .infinity)
        .alert(isPresented: showAlert, error: claimState.error) {
            Button {
                isPresented = false
            } label: {
                SwiftUI.Text(.localizable.ok)
            }
        }
        .task {
            guard case .idle = claimState else {
                return
            }

            guard let keyPair = currentUser.keyPair else {
                claimState = .failed(.notLoggedIn)
                return
            }

            claimState = .claiming

            do {
                try await namesAPI.register(username: username, keyPair: keyPair)
                currentUser.author?.nip05 = "\(username)@nos.social"
                try currentUser.viewContext.saveIfNeeded()
                claimState = .claimed
                analytics.registeredNIP05Username()
            } catch {
                Log.error(error.localizedDescription)
                claimState = .failed(.unableToClaim(error))
            }
        }
        .padding(.horizontal, 40)
        .profileEditSheetPage()
    }

    enum ClaimError: LocalizedError {
        case notLoggedIn
        case unableToClaim(Error)

        var errorDescription: String? {
            switch self {
            case .notLoggedIn:
                return "Not logged in"
            case .unableToClaim(let error):
                return error.localizedDescription
            }
        }
    }
}

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) {
        ClaimYourUniqueIdentityPage(isPresented: .constant(true))
            .presentationDetents([.medium])
    }
}

#Preview {
    PickYourUsernamePage(isPresented: .constant(true))
}

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) {
        ExcellentChoicePage(username: "sebastian", isPresented: .constant(true))
            .presentationDetents([.medium])
    }
}
