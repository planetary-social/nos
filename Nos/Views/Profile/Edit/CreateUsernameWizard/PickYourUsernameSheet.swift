import Combine
import Dependencies
import Logger
import SwiftUI

struct PickYourUsernameSheet: View {

    @Binding var isPresented: Bool
    @State private var usernameObserver = TextDebouncer()
    @State private var verified: Bool?
    @State private var isVerifying = false
    @Dependency(\.namesAPI) private var namesAPI
    @Dependency(\.currentUser) private var currentUser

    var body: some View {
        WizardSheetVStack {
            Button {
                isPresented = false
            } label: {
                Text(.localizable.cancel)
                    .font(.clarity(.medium, textStyle: .body))
                    .foregroundStyle(Color.primaryTxt)
                    .padding(.vertical, 20)
                    .padding(.leading, -20)
            }
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    WizardSheetTitleText(.localizable.pickYourUsernameTitle)
                    WizardSheetDescriptionText(markdown: .localizable.pickYourUsernameDescription)
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
                        Text(".nos.social")
                            .font(.clarity(.bold, textStyle: .title3))
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

                NavigationLink {
                    ExcellentChoiceSheet(username: usernameObserver.text, isPresented: $isPresented)
                } label: {
                    if isVerifying {
                        ZStack {
                            ProgressView()
                                .frame(height: .zero)
                                .tint(Color.white)
                            Text(.localizable.next)
                                .hidden()
                        }
                    } else {
                        Text(.localizable.next)
                    }
                }
                .buttonStyle(BigActionButtonStyle())
                .disabled(verified != true || isVerifying || invalidInput)
                Spacer(minLength: 40)
            }
        }
    }

    private func usernameAlreadyClaimedText() -> some View {
        Text(.localizable.usernameAlreadyClaimed)
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
            verified = try await namesAPI.checkAvailability(
                username: username,
                publicKey: keyPair.publicKey
            )
        } catch {
            Log.error(error.localizedDescription)
        }
    }
}

fileprivate struct UsernameTextField: View {

    @State var usernameObserver: TextDebouncer
    @FocusState private var usernameFieldIsFocused: Bool

    var body: some View {
        TextField(
            text: $usernameObserver.text,
            prompt: Text(.localizable.username).foregroundStyle(Color.secondaryTxt)
        ) {
            Text(.localizable.username)
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

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) {
        PickYourUsernameSheet(isPresented: .constant(true))
            .presentationDetents([.medium])
    }
}
