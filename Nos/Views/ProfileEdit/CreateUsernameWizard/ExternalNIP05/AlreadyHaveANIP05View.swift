import Combine
import Dependencies
import Logger
import SwiftUI

struct AlreadyHaveANIP05View: View {
    @Binding var isPresented: Bool
    @StateObject private var usernameObserver = UsernameObserver()
    @State private var verified: Bool?
    @State private var isVerifying = false
    @Dependency(\.namesAPI) private var namesAPI
    @Dependency(\.currentUser) private var currentUser

    var body: some View {
        WizardSheetVStack {
            Button {
                isPresented = false
            } label: {
                PlainText(.localizable.cancel)
                    .font(.clarity(.medium, textStyle: .body))
                    .foregroundStyle(Color.primaryTxt)
                    .padding(.vertical, 20)
                    .padding(.leading, -20)
            }
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    WizardSheetTitleText(.localizable.linkYourNIP05Title)
                    WizardSheetDescriptionText(markdown: .localizable.linkYourNIP05Description)
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
                    }
                    if linkFailed {
                        unableToLinkUsernameText()
                    } else {
                        unableToLinkUsernameText()
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
                            PlainText(.localizable.next)
                                .hidden()
                        }
                    } else {
                        PlainText(.localizable.next)
                    }
                }
                .buttonStyle(BigActionButtonStyle())
                .disabled(verified != true || isVerifying || invalidInput)
                Spacer(minLength: 40)
            }
        }
    }

    private func unableToLinkUsernameText() -> some View {
        WizardSheetDescriptionText(markdown: .localizable.nip05LinkFailed, tint: .red)
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

    private func verify(_ username: String) async {
        verified = nil

        guard !username.isEmpty, let keyPair = currentUser.keyPair else {
            return
        }

        let components = username.components(separatedBy: "@")

        guard components.count == 2 else {
            return
        }

        let localPart = components[0]
        let domain = components[1]

        guard let host = URL(string: "https://\(domain)/.well-known/nostr.json") else {
            return
        }

        isVerifying = true

        defer {
            isVerifying = false
        }

        do {
            verified = try await namesAPI.verify(username: localPart, host: host, keyPair: keyPair)
        } catch {
            Log.error(error.localizedDescription)
            verified = false
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

fileprivate struct UsernameTextField: View {

    @StateObject var usernameObserver: UsernameObserver
    @FocusState private var usernameFieldIsFocused: Bool

    var body: some View {
        TextField(
            text: $usernameObserver.text,
            prompt: SwiftUI.Text(verbatim: String(localized: .localizable.nip05Example))
                .foregroundStyle(Color.secondaryTxt)
        ) {
            SwiftUI.Text(verbatim: String(localized: .localizable.nip05Example))
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