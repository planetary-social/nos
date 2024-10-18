import Dependencies
import Logger
import SwiftUI

/// The possible states of ``UsernameView``.
fileprivate enum UsernameViewState {
    case idle
    case loading
    case verificationFailed
    case claimed
    case claimFailed
}

/// The Username view in the onboarding.
struct UsernameView: View {
    @Environment(OnboardingState.self) private var state
    @Environment(CurrentUser.self) private var currentUser
    @Environment(\.managedObjectContext) private var viewContext

    @Dependency(\.crashReporting) private var crashReporting
    @Dependency(\.namesAPI) private var namesAPI

    @State private var username = ""
    @State private var usernameState: UsernameViewState = .idle
    @State private var saveError: SaveProfileError?

    private var showAlert: Binding<Bool> {
        Binding {
            saveError != nil
        } set: { _ in
            saveError = nil
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
            ViewThatFits(in: .vertical) {
                displayNameStack

                ScrollView {
                    displayNameStack
                }
            }
        }
        .navigationBarHidden(true)
        .alert(isPresented: showAlert, error: saveError) {
            Button {
                saveError = nil
                Task {
                    await save()
                }
            } label: {
                Text("retry")
            }
            Button {
                saveError = nil
            } label: {
                Text("cancel")
            }
        }
    }

    var displayNameStack: some View {
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
                await next()
            }
            .disabled(nextButtonDisabled)
        }
        .padding(40)
        .readabilityPadding()
    }

    var usernameAlreadyClaimedText: some View {
        Text("usernameNotAvailable")
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(Color.error)
    }

    /// Checks whether the username is available and saves it. Updates `usernameState` based on the result.
    func next() async {
        usernameState = .loading

        guard !username.isEmpty, let keyPair = currentUser.keyPair else {
            usernameState = .claimFailed
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
    func save() async {
        usernameState = .loading

        guard let author = await currentUser.author,
            let keyPair = currentUser.keyPair else {
            saveError = SaveProfileError.unexpectedError
            usernameState = .claimFailed
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
            state.step = .buildYourNetwork
        } catch CurrentUserError.errorWhilePublishingToRelays {
            saveError = SaveProfileError.unableToPublishChanges
            usernameState = .claimFailed
        } catch {
            crashReporting.report(error)
            saveError = SaveProfileError.unexpectedError
            usernameState = .claimFailed
        }
    }
}

#Preview {
    UsernameView()
        .environment(OnboardingState())
        .inject(previewData: PreviewData())
}
