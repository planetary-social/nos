import Dependencies
import Logger
import SwiftUI

/// The possible states of ``UsernameView``.
fileprivate enum UsernameViewState {
    case idle
    case loading
    case verificationFailed
    case claimed
    case errorAlert
}

/// The Username view in the onboarding.
struct UsernameView: View {
    @Environment(OnboardingState.self) private var state
    @Environment(CurrentUser.self) private var currentUser
    @Environment(\.managedObjectContext) private var viewContext
    @FocusState private var isTextFieldFocused: Bool

    @Dependency(\.crashReporting) private var crashReporting
    @Dependency(\.namesAPI) private var namesAPI

    @State private var username = ""
    @State private var usernameState: UsernameViewState = .idle

    private var showAlert: Binding<Bool> {
        Binding {
            usernameState == .errorAlert
        } set: { _ in
            usernameState = .idle
        }
    }

    private var nextButtonDisabled: Bool {
        if username.isEmpty {
            return true
        } else if usernameState == .loading {
            return true
        } else if usernameState == .claimed {
            return true
        } else {
            return false
        }
    }

    var body: some View {
        ZStack {
            Color.appBg
                .ignoresSafeArea()
            ViewThatFits {
                usernameStack
                
                ScrollView {
                    usernameStack
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            isTextFieldFocused = true
        }
        .ignoresSafeArea(.keyboard)
        .interactiveDismissDisabled()
        .alert("", isPresented: showAlert) {
            Button {
                nextStep()
            } label: {
                Text("skipForNow")
            }
        } message: {
            Text("errorConnecting")
        }
    }

    private var usernameStack: some View {
        VStack(alignment: .leading, spacing: 20) {
            LargeNumberView(4)
            HStack(alignment: .firstTextBaseline) {
                Text("usernameHeadline")
                    .font(.clarityBold(.title))
                    .foregroundStyle(Color.primaryTxt)
                Text("usernameNIP05Parenthetical")
                    .font(.clarityRegular(.title2))
                    .foregroundStyle(Color.secondaryTxt)
            }
            Text("usernameDescription")
                .font(.body)
                .foregroundStyle(Color.secondaryTxt)
            HStack {
                TextField(
                    "",
                    text: $username,
                    prompt: Text("usernamePlaceholder")
                        .foregroundStyle(Color.textFieldPlaceholder)
                )
                .textInputAutocapitalization(.never)
                .foregroundStyle(Color.primaryTxt)
                .fontWeight(.bold)
                .autocorrectionDisabled()
                .focused($isTextFieldFocused)
                .padding()
                .withStyledBorder()

                Text("@nos.social")
                    .fontWeight(.bold)
                    .foregroundStyle(Color.secondaryTxt)
            }
            if usernameState == .verificationFailed {
                usernameAlreadyClaimedText
            }
            Spacer()
            BigActionButton("next") {
                await verifyAndSave()
            }
            .disabled(nextButtonDisabled)
        }
        .padding(40)
        .readabilityPadding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var usernameAlreadyClaimedText: some View {
        Text("usernameNotAvailable")
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(Color.error)
    }

    private func nextStep() {
        state.step = .accountSuccess
    }

    /// Checks whether the username is available and saves it. Updates `usernameState` based on the result.
    private func verifyAndSave() async {
        usernameState = .loading

        guard !username.isEmpty, let keyPair = currentUser.keyPair else {
            usernameState = .errorAlert
            return
        }

        do {
            let verified = try await namesAPI.checkAvailability(
                username: username,
                publicKey: keyPair.publicKey
            )
            guard verified else {
                usernameState = .verificationFailed
                return
            }
            await save()
        } catch {
            Log.error(error.localizedDescription)
            usernameState = .verificationFailed
        }
    }
    
    /// Saves the username locally, publishes the metadata, and registers it.
    private func save() async {
        usernameState = .loading

        guard let author = await currentUser.author,
            let keyPair = currentUser.keyPair else {
            usernameState = .errorAlert
            return
        }

        author.nip05 = "\(username)@nos.social"
        do {
            try viewContext.save()
            try await currentUser.publishMetadata()
            let relays = author.relays.compactMap {
                $0.addressURL
            }
            try await namesAPI.register(
                username: username,
                keyPair: keyPair,
                relays: relays
            )
            usernameState = .claimed
            state.usernameSucceeded = true
            nextStep()
        } catch {
            crashReporting.report(error)
            usernameState = .errorAlert
        }
    }
}

#Preview {
    UsernameView()
        .environment(OnboardingState())
        .inject(previewData: PreviewData())
}
