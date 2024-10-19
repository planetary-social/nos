import Dependencies
import Logger
import SwiftUI

struct ExcellentChoiceSheet: View {

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
        WizardSheetVStack {
            Spacer(minLength: 40)
            switch claimState {
            case .idle, .claiming:
                ProgressView()
                    .tint(Color.accentColor)
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed(let error):
                Text(error.localizedDescription)
                    .font(.clarity(.regular, textStyle: .callout))
                    .foregroundStyle(Color.primaryTxt)
            case .claimed:
                WizardSheetTitleText("excellentChoice")
                Text(attributedUsername)
                    .font(.clarity(.bold, textStyle: .title3))
                    .foregroundStyle(Color.secondaryTxt)
                WizardSheetDescriptionText(markdown: AttributedString(localized: "usernameClaimedNotice"))

                Spacer(minLength: 0)

                Button("done") {
                    isPresented = false
                }
                .buttonStyle(BigActionButtonStyle())
            }
            Spacer(minLength: 40)
        }
        .alert(isPresented: showAlert, error: claimState.error) {
            Button {
                isPresented = false
            } label: {
                Text("ok")
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

            let oldNIP05 = currentUser.author?.nip05
            do {
                currentUser.author?.nip05 = "\(username)@nos.social"
                try currentUser.viewContext.saveIfNeeded()
                try await currentUser.publishMetadata()
                let relays = currentUser.author?.relays.compactMap {
                    $0.addressURL
                }
                try await namesAPI.register(
                    username: username,
                    keyPair: keyPair,
                    relays: relays ?? []
                )
                claimState = .claimed
                analytics.registeredNIP05Username()
            } catch {
                Log.error(error.localizedDescription)
                
                // Do our best reverting the changes.
                currentUser.author?.nip05 = oldNIP05
                try? currentUser.viewContext.saveIfNeeded()
                try? await currentUser.publishMetadata()

                claimState = .failed(.unableToClaim(error))
            }
        }
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
        ExcellentChoiceSheet(username: "sebastian", isPresented: .constant(true))
            .presentationDetents([.medium])
    }
}
