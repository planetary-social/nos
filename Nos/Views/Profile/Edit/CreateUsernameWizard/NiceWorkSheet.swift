import Dependencies
import Logger
import SwiftUI

struct NiceWorkSheet: View {

    let username: String
    @Binding var isPresented: Bool

    @State private var connectState: ConnectState = .idle
    @Dependency(\.currentUser) private var currentUser
    @Dependency(\.analytics) private var analytics

    /// The current state of the connect request.
    private enum ConnectState {
        /// There is no request in progress yet
        case idle

        /// The request is in progress
        case connecting

        /// The request finished successfully
        case connected

        /// Something was wrong with the request
        case failed(ConnectError)

        var hasError: Bool {
            error != nil
        }

        var error: ConnectError? {
            switch self {
            case .failed(let error):
                return error
            default:
                return nil
            }
        }
    }

    private var showAlert: Binding<Bool> {
        Binding {
            connectState.hasError
        } set: { _ in
        }
    }

    var body: some View {
        WizardSheetVStack {
            Spacer(minLength: 40)
            switch connectState {
            case .idle, .connecting:
                ProgressView()
                    .tint(Color.accentColor)
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed(let error):
                SwiftUI.Text(error.localizedDescription)
                    .font(.clarity(.regular, textStyle: .callout))
                    .foregroundStyle(Color.primaryTxt)
            case .connected:
                WizardSheetTitleText("niceWork")
                WizardSheetDescriptionText("nip05Connected")

                Spacer(minLength: 0)

                Button("done") {
                    isPresented = false
                }
                .buttonStyle(BigActionButtonStyle())
            }
            Spacer(minLength: 40)
        }
        .alert(isPresented: showAlert, error: connectState.error) {
            Button {
                isPresented = false
            } label: {
                SwiftUI.Text("ok")
            }
        }
        .task {
            guard case .idle = connectState else {
                return
            }

            guard currentUser.keyPair != nil else {
                connectState = .failed(.notLoggedIn)
                return
            }

            connectState = .connecting

            let oldNIP05 = currentUser.author?.nip05
            do {
                currentUser.author?.nip05 = "\(username)"
                try currentUser.viewContext.saveIfNeeded()
                try await currentUser.publishMetadata()
                connectState = .connected
                analytics.linkedNIP05Username()
            } catch {
                Log.error(error.localizedDescription)

                // Revert the changes
                currentUser.author?.nip05 = oldNIP05
                try? currentUser.viewContext.saveIfNeeded()

                connectState = .failed(.unableToConnect(error))
            }
        }
    }

    private enum ConnectError: LocalizedError {
        case notLoggedIn
        case unableToConnect(Error)

        var errorDescription: String? {
            switch self {
            case .notLoggedIn:
                return "Not logged in"
            case .unableToConnect(let error):
                return error.localizedDescription
            }
        }
    }
}

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) {
        NiceWorkSheet(username: "sebastian", isPresented: .constant(true))
            .presentationDetents([.medium])
    }
}
