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
//    @State private var confirmReport = false
    @State private var showMuteDialog = false
    @State private var confirmationDialogState: ConfirmationDialogState<UserSelection>?
    
    @Environment(\.managedObjectContext) private var viewContext
    
    // swiftlint:disable function_body_length
    func body(content: Content) -> some View {
        content
        // ReportCategory menu
            .confirmationDialog($confirmationDialogState, action: processUserSelection)
//            .alert(
//                String(localized: .localizable.confirmFlag),
//                isPresented: $confirmReport,
//                actions: {
//                    Button(String(localized: .localizable.confirm)) {
//                        publishReport(userSelection)
//                        
//                        if let author = reportedObject.author, !author.muted {
//                            showMuteDialog = true
//                        }
//                    }
//                    Button(String(localized: .localizable.cancel), role: .cancel) {
//                        userSelection = nil
//                    }
//                },
//                message: {
//                    let text = getAlertMessage(for: userSelection, with: reportedObject)
//                    Text(text)
//                }
//            )
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
                    confirmationDialogState = ConfirmationDialogState<UserSelection>(
                        title: { TextState(String(localized: .localizable.reportContent)) },
                        actions: {
                            for button in topLevelButtons() {
                                button
                            }
                        },
                        message: { TextState(String(localized: message)) }
                    )
                }
            }
            .onChange(of: confirmationDialogState) { _, newValue in
                if newValue == nil {
                    Log.debug("newValue of confirmationDialogState is nil; setting isPresented = false")
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
                confirmationDialogState = ConfirmationDialogState<UserSelection>(
                    title: { TextState(String(localized: .localizable.reportActionTitle(category.displayName))) },
                    actions: {
                        ButtonState(action: .send(.sendToNos(category))) {
                            TextState("Send to Nos")
                        }
                        ButtonState(action: .send(.flagPublicly(category))) {
                            TextState("Flag Publicly")
                        }
                    },
                    message: { TextState(String(localized: .localizable.reportActionTitle(category.displayName))) }
                )
            }
            
        case .authorCategorySelected(let category):
            Task {
                confirmationDialogState = ConfirmationDialogState<UserSelection>(
                    title: { TextState(String(localized: .localizable.reportActionTitle(category.displayName))) },
                    actions: {
                        ButtonState(action: .send(.sendToNos(category))) {
                            TextState("Send to Nos")
                        }
                        ButtonState(action: .send(.flagPublicly(category))) {
                            TextState("Flag Publicly")
                        }
                    },
                    message: { TextState(String(localized: .localizable.reportActionTitle(category.displayName))) }
                )
            }
            
        case .sendToNos, .flagPublicly:
            Task {
                confirmationDialogState = ConfirmationDialogState<UserSelection>(
                    title: {
                        TextState(String(localized: .localizable.confirmFlag))
                    },
                    actions: {
                        ButtonState(action: .send(.publishReport)) {
                            TextState(String(localized: .localizable.confirm))
                        }
                        ButtonState(role: .cancel) {
                            TextState(String(localized: .localizable.cancel))
                        }
                    },
                    message: {
                        TextState(getAlertMessage(for: userSelection, with: reportedObject))
                    }
                )
            }
        case .publishReport:
            // Task { ???
            publishReport(userSelection)
            // } ???
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
        case publishReport

        var displayName: String {
            switch self {
            case .noteCategorySelected(let category),
                .authorCategorySelected(let category),
                .sendToNos(let category),
                .flagPublicly(let category):
                return category.displayName
            case .publishReport:
                return "Publish!"
            }
        }
        
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

            case .publishReport:
//                return userSelection?.confirmationAlertMessage(for: reportedObject) ?? String(localized: .localizable.error)
                return "oops, not sure what to display here"
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
        case .publishReport:
            Log.error("Better fill this in")
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
