import SwiftUI
import Dependencies
import Logger
import SwiftUINavigation

/// The report menu can be added to another element and controlled with the `isPresented` variable. When `isPresented`
/// is set to `true` it will walk the user through a series of menus that allows them to report content in a given
/// category and optionally mute the respective author.
struct ReportMenuModifier: ViewModifier {
    
    @Binding var isPresented: Bool
    
    var reportedObject: ReportTarget
    
    @State private var userSelection: UserSelection?
    @State private var confirmReport = false
    @State private var showMuteDialog = false
    @State private var confirmationDialogState: ConfirmationDialogState<UserSelection>?
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var relayService: RelayService
    @Environment(CurrentUser.self) private var currentUser
    @Dependency(\.analytics) private var analytics: Analytics
    
    // swiftlint:disable function_body_length
    func body(content: Content) -> some View {
        content
        // ReportCategory menu
            .confirmationDialog($confirmationDialogState, action: processUserSelection)
            .alert(
                String(localized: .localizable.confirmFlag),
                isPresented: $confirmReport,
                actions: {
                    Button(String(localized: .localizable.confirm)) {
                        publishReport(userSelection)
                        if let author = reportedObject.author, !author.muted {
                            showMuteDialog = true
                        }
                    }
                    Button(String(localized: .localizable.cancel), role: .cancel) {
                        userSelection = nil
                    }
                },
                message: {
                    Text(userSelection?.confirmationAlertMessage ?? String(localized: .localizable.error))
                }
            )
        // Mute user menu
            .alert(
                String(localized: .localizable.muteUser),
                isPresented: $showMuteDialog,
                actions: {
                    if let author = reportedObject.author {
                        Button(String(localized: .localizable.yes)) {
                            mute(author: author)
                        }
                        Button(String(localized: .localizable.no)) {}
                    }
                },
                message: {
                    if let author = reportedObject.author {
                        Text(.localizable.mutePrompt(author.safeName))
                    } else {
                        Text(.localizable.error)
                    }
                }
            )
            .onChange(of: isPresented) { _, shouldPresent in
                if shouldPresent {
                    confirmationDialogState = ConfirmationDialogState(
                        title: TextState(String(localized: .localizable.reportContent)),
                        message: TextState(String(localized: .localizable.reportContentMessage)),
                        buttons: topLevelButtons()
                    )
                } else {
                    confirmationDialogState = nil
                }
            }
            .onChange(of: confirmationDialogState) { _, newValue in
                if newValue == nil {
                    isPresented = false
                }
            }
    }
    // swiftlint:enable function_body_length
    
    func processUserSelection(_ userSelection: UserSelection?) {
        self.userSelection = userSelection
        
        guard let userSelection else {
            return
        }
        
        switch userSelection {
        case .selected(let category):
            Task {
                confirmationDialogState = ConfirmationDialogState(
                    title: TextState(String(localized: .localizable.reportActionTitle(category.displayName))),
                    message: TextState(String(localized: .localizable.reportActionTitle(category.displayName))),
                    buttons: [
                        ButtonState(action: .send(.sendToNos(category))) {
                            TextState("Send to Nos")
                        },
                        ButtonState(action: .send(.flagPublicly(category))) {
                            TextState("Flag Publicly")
                        }
                    ]
                )
            }
            
        case .sendToNos, .flagPublicly:
            confirmReport = true
        }
    }
    
    func mute(author: Author) {
        Task {
            do {
                try await author.mute(viewContext: viewContext)
            } catch {
                Log.error(error.localizedDescription)
            }
        }
    }
    
    typealias TopLevelDisplayName = String
    /// An enum to simplify the user selection through the sequence of connected
    /// dialogs
    enum UserSelection: Equatable {
        case selected(ReportCategory)
        case sendToNos(ReportCategory)
        case flagPublicly(ReportCategory)
        
        var displayName: String {
            switch self {
            case .selected(let category), .sendToNos(let category), .flagPublicly(let category):
                return category.displayName
            }
        }

        var confirmationAlertMessage: String {
            switch self {
            case .sendToNos(let category):
                return String(localized: .localizable.reportSendToNosConfirmation(category.displayName))
            case .flagPublicly(let category):
                return String(localized: .localizable.reportFlagPubliclyConfirmation(category.displayName))
            case .selected(let category):
                Log.error("Invalid .selected variant")
                return String(localized: .localizable.reportFlagPubliclyConfirmation(category.displayName))
            }
        }
    }
    
    /// List of the top-level report categories we care about
    /// Out vocabulary is much bigger
    func topLevelButtons() -> [ButtonState<UserSelection>] {
        return selectableCategories.map { category in
            let userSelection = UserSelection.selected(category)
            
            return ButtonState(action: .send(userSelection)) {
                TextState(verbatim: category.displayName)
            }
        }
    }
    
    /// Publishes a report for the currently selected
    func publishReport(_ userSelection: UserSelection?) {
        switch userSelection {
        case .sendToNos(let selectedCategory):
            sendToNos(selectedCategory)
        case .flagPublicly(let selectedCategory):
            flagPublicly(selectedCategory)
        case .selected, .none:
            // This would be a dev error
            Log.error("Invalid user selection")
        }
    }
    
    func sendToNos(_ selectedCategory: ReportCategory) {
        #warning("Not implemented yet")
        print("sendToNos not implemented yet for category \(selectedCategory) for target \(reportedObject)")
    }
    
    func flagPublicly(_ selectedCategory: ReportCategory) {
        guard let keyPair = currentUser.keyPair else {
            Log.error("Cannot publish report - No signed in user")
            return
        }
        
        var event = JSONEvent(
            pubKey: keyPair.publicKeyHex,
            kind: .report,
            tags: [
                ["L", "MOD"],
                ["l", "MOD>\(selectedCategory.code)", "MOD"]
            ],
            content: String(localized: .localizable.reportEventContent(selectedCategory.displayName))
        )
        
        let nip56Reason = selectedCategory.nip56Code.rawValue
        event.tags += reportedObject.tags(for: nip56Reason)
        
        Task {
            do {
                try await relayService.publishToAll(event: event, signingKey: keyPair, context: viewContext)
                analytics.reported(reportedObject)
            } catch {
                Log.error("Failed to publish report: \(error.localizedDescription)")
            }
        }
    }
}

extension View {
    /// The report menu can be added to another element and controlled with the `isPresented` variable. When
    /// `isPresented` is set to `true` it will walk the user through a series of menus that allows them to report
    /// content in a given category and optionally mute the respective author.
    func reportMenu(_ show: Binding<Bool>, reportedObject: ReportTarget) -> some View {
        self.modifier(ReportMenuModifier(isPresented: show, reportedObject: reportedObject))
    }
}

struct ReportMenu_Previews: PreviewProvider {
    static var previewData = PreviewData()
    static var previews: some View {
        StatefulPreviewContainer(false) { binding in
            VStack {
                Button("Report this") {
                    binding.wrappedValue.toggle()
                }
                .reportMenu(binding, reportedObject: .note(previewData.imageNote))
            }
        }
    }
}
