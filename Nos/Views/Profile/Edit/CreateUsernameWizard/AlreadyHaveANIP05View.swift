import Combine
import Dependencies
import Logger
import SwiftUI

struct AlreadyHaveANIP05View: View {
    @Binding var isPresented: Bool
    @State var usernameObserver = TextDebouncer()
    @State private var verified: Bool?
    @State private var isVerifying = false
    @State private var verifyTask: Task<Void, Never>?
    @Dependency(\.namesAPI) private var namesAPI
    @Dependency(\.currentUser) private var currentUser

    var body: some View {
        WizardSheetVStack {
            Button {
                isPresented = false
            } label: {
                Text("cancel")
                    .font(.clarity(.medium, textStyle: .body))
                    .foregroundStyle(Color.primaryTxt)
                    .padding(.vertical, 20)
                    .padding(.leading, -20)
            }
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    WizardSheetTitleText("linkYourNIP05Title")
                    WizardSheetDescriptionText(markdown: AttributedString(localized: "linkYourNIP05Description"))
                    HStack {
                        UsernameTextField(usernameObserver: usernameObserver)
                            .onChange(of: usernameObserver.debouncedText) { _, newValue in
                                verifyTask?.cancel()
                                verifyTask = Task {
                                    do {
                                        try await verify(newValue)
                                    } catch {
                                        Log.debug(error.localizedDescription)
                                    }
                                }
                            }
                            .onSubmit {
                                verifyTask?.cancel()
                                verifyTask = Task {
                                    do {
                                        try await verify(usernameObserver.text)
                                    } catch {
                                        Log.debug(error.localizedDescription)
                                    }
                                }
                            }
                    }
                    if linkFailed {
                        unableToLinkUsernameText
                    } else {
                        unableToLinkUsernameText
                            .hidden()
                    }

                    Spacer(minLength: 0)
                }

                NavigationLink {
                    NiceWorkSheet(username: usernameObserver.text, isPresented: $isPresented)
                } label: {
                    if isVerifying {
                        ZStack {
                            ProgressView()
                                .frame(height: .zero)
                                .tint(Color.white)
                            Text("next")
                                .hidden()
                        }
                    } else {
                        Text("next")
                    }
                }
                .buttonStyle(BigActionButtonStyle())
                .disabled(verified != true || isVerifying || !invalidInput)
                Spacer(minLength: 40)
            }
        }
    }

    private var unableToLinkUsernameText: some View {
        WizardSheetDescriptionText(markdown: AttributedString(localized: "nip05LinkFailed"), tint: .red)
            .font(.clarity(.medium, textStyle: .subheadline))
            .lineSpacing(3)
    }

    private var invalidInput: Bool {
        let input = usernameObserver.text
        let emailRegEx = "[0-9a-z._-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: input)
    }

    private var linkFailed: Bool {
        verified == false
    }

    private func verify(_ username: String) async throws {
        verified = nil

        guard !username.isEmpty, let keyPair = currentUser.keyPair else {
            return
        }

        isVerifying = true

        let result: Bool
        do {
            result = try await namesAPI.verify(
                username: username,
                publicKey: keyPair.publicKey
            )
        } catch {
            Log.error(error.localizedDescription)
            result = false
        }
        try Task.checkCancellation()
        verified = result
        isVerifying = false
    }
}

fileprivate struct UsernameTextField: View {

    @Bindable var usernameObserver: TextDebouncer
    @FocusState private var usernameFieldIsFocused: Bool

    var body: some View {
        TextField(
            text: $usernameObserver.text,
            prompt: SwiftUI.Text(verbatim: String(localized: "nip05Example"))
                .foregroundStyle(Color.secondaryTxt)
        ) {
            SwiftUI.Text(verbatim: String(localized: "nip05Example"))
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
        .padding(1)
        .onChange(of: usernameObserver.text) { oldValue, newValue in
            let characterset = CharacterSet(
                charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._@"
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

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) {
        AlreadyHaveANIP05View(isPresented: .constant(true))
            .presentationDetents([.medium])
    }
}
