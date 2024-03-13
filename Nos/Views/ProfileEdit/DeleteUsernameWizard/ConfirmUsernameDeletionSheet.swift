//
//  ConfirmUsernameDeletionSheet.swift
//  Nos
//
//  Created by Martin Dutra on 5/3/24.
//

import Dependencies
import SwiftUI

struct ConfirmUsernameDeletionSheet: View {

    var author: Author
    @Binding var isPresented: Bool

    @Environment(CurrentUser.self) private var currentUser
    @Environment(\.managedObjectContext) private var viewContext
    
    @Dependency(\.crashReporting) private var crashReporting
    @Dependency(\.namesAPI) private var namesAPI
    @Dependency(\.analytics) private var analytics

    @State private var deleteState: DeleteState = .idle

    private var showAlert: Binding<Bool> {
        Binding {
            deleteState.hasError
        } set: { _ in
        }
    }

    private var isDeleting: Bool {
        guard case .deleting = deleteState else {
            return false
        }
        return true
    }

    var body: some View {
        WizardSheetVStack {
            Spacer(minLength: 40)
            WizardSheetTitleText(.localizable.deleteUsernameConfirmation)
            WizardSheetDescriptionText(markdown: .localizable.deleteUsernameDescription)

            Spacer(minLength: 0)

            Button {
                Task {
                    await deleteUsername()
                }
            } label: {
                let label = PlainText(.localizable.deleteUsername)
                if isDeleting {
                    ZStack {
                        ProgressView()
                            .frame(height: .zero)
                            .tint(Color.white)
                        label
                            .hidden()
                    }
                } else {
                    label
                }
            }
            .buttonStyle(BigActionButtonStyle())
            Button {
                isPresented = false
            } label: {
                SwiftUI.Text(.localizable.cancel)
                    .font(.clarity(.medium, textStyle: .footnote))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .disabled(isDeleting)

            Spacer(minLength: 20)
        }
        .alert(isPresented: showAlert, error: deleteState.error) {
            Button {
                isPresented = false
            } label: {
                SwiftUI.Text(.localizable.ok)
            }
        }
    }

    private func deleteUsername() async {
        guard !isDeleting else {
            return
        }

        guard let keyPair = currentUser.keyPair else {
            deleteState = .failed(.notLoggedIn)
            return
        }
        deleteState = .deleting
        let username = author.nosNIP05Username
        let isNosSocialUsername = author.hasNosNIP05
        author.nip05 = ""
        do {
            try viewContext.save()
            await currentUser.publishMetaData()
            if isNosSocialUsername {
                try? await namesAPI.delete(
                    username: username,
                    keyPair: keyPair
                )
            }
            analytics.deletedNIP05Username()
            deleteState = .deleted
            isPresented = false
        } catch {
            crashReporting.report(error)
            deleteState = .failed(.unableToDelete(error))
        }
    }
}

/// The current state of the delete request.
fileprivate enum DeleteState {
    /// There is no request in progress yet
    case idle

    /// The request is in progress
    case deleting

    /// The request finished successfully
    case deleted

    /// Something was wrong with the request
    case failed(DeleteError)

    var hasError: Bool {
        error != nil
    }

    var error: DeleteError? {
        switch self {
        case .failed(let error):
            return error
        default:
            return nil
        }
    }
}

fileprivate enum DeleteError: LocalizedError {
    case notLoggedIn
    case unableToDelete(Error)

    var errorDescription: String? {
        switch self {
        case .notLoggedIn:
            return "Not logged in"
        case .unableToDelete(let error):
            return error.localizedDescription
        }
    }
}

#Preview {
    var previewData = PreviewData()
    return Color.clear.sheet(isPresented: .constant(true)) {
        ConfirmUsernameDeletionSheet(
            author: previewData.alice,
            isPresented: .constant(true)
        )
    }
    .inject(previewData: previewData)
}
