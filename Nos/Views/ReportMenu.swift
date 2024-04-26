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
    
    @State private var selectedCategory: ReportCategory?
    @State private var confirmReport = false
    @State private var showMuteDialog = false
    @State private var confirmationDialog: ConfirmationDialogState<ReportCategory>? 
    
    @Environment(\.managedObjectContext) private var viewContext
    
    // swiftlint:disable function_body_length
    func body(content: Content) -> some View {
        content
            // ReportCategory menu
            .confirmationDialog($confirmationDialog, action: userSelectedCategory)
            // Report confirmation menu
            .alert(
                String(localized: .localizable.confirmReport),
                isPresented: $confirmReport,
                actions: { 
                    Button(String(localized: .localizable.confirm)) {
                        guard let selectedCategory else {
                            Log.error("No selected category, skipping report.")
                            return
                        }
                        
                        ReportPublisher().publishPublicReport(
                            for: reportedObject, 
                            category: selectedCategory, 
                            context: viewContext
                        )
                        
                        if let author = reportedObject.author, !author.muted {
                            showMuteDialog = true
                        }
                    }
                    Button(String(localized: .localizable.cancel), role: .cancel) {
                        selectedCategory = nil
                    }
                },
                message: {
                    Text(
                        .localizable.reportConfirmation(
                            selectedCategory?.displayName ?? String(localized: .localizable.error)
                        )
                    )
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
                    confirmationDialog = ConfirmationDialogState(
                        title: TextState(String(localized: .localizable.reportContent)),
                        buttons: subCategoryButtons(for: topLevelCategories)
                    )
                } else {
                    confirmationDialog = nil
                }
            }
            .onChange(of: confirmationDialog) { _, newValue in
                if newValue == nil {
                    isPresented = false
                }
            }
    }
    // swiftlint:enable function_body_length
    
    func userSelectedCategory(_ category: ReportCategory?) {
        self.selectedCategory = category
        
        guard let category else {
            return
        }
        
        if category.subCategories?.count ?? 0 == 0 {
            confirmReport = true
        } else {
            Task {
                confirmationDialog = ConfirmationDialogState(
                    title: TextState(String(localized: .localizable.reportContent)),
                    buttons: subCategoryButtons(for: category.subCategories ?? [])
                )
            }
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

    /// Generates a series of Buttons for the given report categories.
    func subCategoryButtons(for categories: [ReportCategory]) -> [ButtonState<ReportCategory>] {
        categories.map { subCategory in
            ButtonState(action: .send(subCategory)) {
                TextState(verbatim: subCategory.displayName)
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
