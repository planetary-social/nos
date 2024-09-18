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
    @State private var selectedFlagOption: FlagOption?

    @Environment(\.managedObjectContext) private var viewContext
    @Dependency(\.featureFlags) private var featureFlags

    func body(content: Content) -> some View {
        Group {
            if featureFlags.isEnabled(.newModerationFlow) {
                newModerationFlow(content: content)
            } else {
                oldModerationFlow(content: content)
            }
        }
    }

    /// Displays the moderation flow based on the reported object type. The old flow is still displayed for the author.
    @ViewBuilder
    private func newModerationFlow(content: Content) -> some View {
        switch reportedObject {
        case .note:
            content
                .sheet(isPresented: $isPresented) {
                    ContentFlagView(
                        selectedFlagOptionCategory: $selectedFlagOption
                    )
                }
        case .author:
            oldModerationFlow(content: content)
        }
    }

    // swiftlint:disable function_body_length
    @ViewBuilder
    func oldModerationFlow(content: Content) -> some View {
        content
        // ReportCategory menu
            .confirmationDialog(unwrapping: $confirmationDialogState, action: processUserSelection)
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
                    let text = getAlertMessage(for: userSelection, with: reportedObject)
                    Text(text)
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
                    let message: LocalizedStringResource
                    if case .noteCategorySelected = userSelection {
                        message = .localizable.reportContentMessage
                    } else {
                        message = .localizable.flagUserMessage
                    }
                    confirmationDialogState = ConfirmationDialogState(
                        title: TextState(String(localized: .localizable.reportContent)),
                        message: TextState(String(localized: message)),
                        buttons: topLevelButtons()
                    )
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
        case .noteCategorySelected(let category):
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
            
        case .authorCategorySelected(let category):
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
    
    /// An enum to simplify the user selection through the sequence of connected
    /// dialogs
    enum UserSelection: Equatable {
        case noteCategorySelected(ReportCategory)
        case authorCategorySelected(ReportCategory)
        case sendToNos(ReportCategory)
        case flagPublicly(ReportCategory)
        
        func confirmationAlertMessage(for reportedObject: ReportTarget) -> String {
            switch self {
            case .sendToNos(let category):
                switch reportedObject {
                case .note:
                    return String(localized: .localizable.reportNoteSendToNosConfirmation(category.displayName))
                case .author:
                    return String(localized: .localizable.reportAuthorSendToNosConfirmation)
                }
                
            case .flagPublicly(let category):
                return String(localized: .localizable.reportFlagPubliclyConfirmation(category.displayName))
                
            case .noteCategorySelected(let category),
                .authorCategorySelected(let category):
                return String(localized: .localizable.reportFlagPubliclyConfirmation(category.displayName))
            }
        }
    }
    
    /// List of the top-level report categories we care about.
    func topLevelButtons() -> [ButtonState<UserSelection>] {
        switch reportedObject {
        case .note:
            ReportCategoryType.noteCategories.map { category in
                let userSelection = UserSelection.noteCategorySelected(category)
                
                return ButtonState(action: .send(userSelection)) {
                    TextState(verbatim: category.displayName)
                }
            }
        case .author:
            ReportCategoryType.authorCategories.map { category in
                let userSelection = UserSelection.authorCategorySelected(category)
                
                return ButtonState(action: .send(userSelection)) {
                    TextState(verbatim: category.displayName)
                }
            }
        }
    }
    
    /// Publishes a report based on user input
    func publishReport(_ userSelection: UserSelection?) {
        switch userSelection {
        case .sendToNos(let selectedCategory):
            sendToNos(selectedCategory)
        case .flagPublicly(let selectedCategory):
            flagPublicly(selectedCategory)
        case .noteCategorySelected, .authorCategorySelected, .none:
            // This would be a dev error
            Log.error("Invalid user selection")
        }
    }
    
    func sendToNos(_ selectedCategory: ReportCategory) {
        ReportPublisher().publishPrivateReport(
            for: reportedObject,
            category: selectedCategory,
            context: viewContext
        )
    }
    
    func flagPublicly(_ selectedCategory: ReportCategory) {
        ReportPublisher().publishPublicReport(
            for: reportedObject,
            category: selectedCategory,
            context: viewContext
        )
    }
    
    func getAlertMessage(for userSelection: UserSelection?, with reportedObject: ReportTarget) -> String {
        userSelection?.confirmationAlertMessage(for: reportedObject) ?? String(localized: .localizable.error)
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
