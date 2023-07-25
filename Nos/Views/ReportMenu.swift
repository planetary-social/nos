//
//  ReportMenu.swift
//  Nos
//
//  Created by Matthew Lorentz on 5/24/23.
//

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
    @State private var previouslySelectedCategory: ReportCategory?
    @State private var confirmationDialog: ConfirmationDialogState<ReportCategory>? 
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var relayService: RelayService
    @EnvironmentObject private var currentUser: CurrentUser
    @Dependency(\.analytics) private var analytics: Analytics
    
    // swiftlint:disable function_body_length
    func body(content: Content) -> some View {
        content
            // ReportCategory menu
            .confirmationDialog(unwrapping: $confirmationDialog, action: userSelectedCategory)
            // Report confirmation menu
            .alert(
                Localized.confirmReport.string, 
                isPresented: $confirmReport,
                actions: { 
                    Button(Localized.confirm.string) { 
                        publishReport()
                        if let author = reportedObject.author, !author.muted {
                            showMuteDialog = true
                        }
                    }
                    Button(Localized.cancel.string, role: .cancel) { 
                        selectedCategory = nil
                    }
                },
                message: {
                    Localized.reportConfirmation.view(
                        ["report_type": selectedCategory?.displayName ?? Localized.error.string]
                    )
                }
            ) 
            // Mute user menu
            .alert(
                Localized.muteUser.string, 
                isPresented: $showMuteDialog,
                actions: { 
                    if let author = reportedObject.author {
                        Button(Localized.yes.string) { 
                            mute(author: author)
                        }
                        Button(Localized.no.string) {}
                    }
                },
                message: {
                    if let author = reportedObject.author {
                        Localized.mutePrompt.view(["user": author.safeName])
                    } else {
                        Localized.error.view
                    }
                }
            ) 
            .onChange(of: isPresented) { shouldPresent in
                if shouldPresent {
                    confirmationDialog = ConfirmationDialogState(
                        title: Localized.reportContent.textState, 
                        buttons: subCategoryButtons(for: topLevelCategories)
                    )
                } else {
                    confirmationDialog = nil
                }
            }
            .onChange(of: confirmationDialog) { newValue in
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
                    title: Localized.reportContent.textState, 
                    buttons: subCategoryButtons(for: category.subCategories ?? [])
                )
            }
        }
    }

    func mute(author: Author) {
        Task {
            do {
                try await author.mute(context: viewContext)
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
    
    /// Publishes a report for the currently selected 
    func publishReport() {
        guard let keyPair = currentUser.keyPair,
            let selectedCategory else {
            Log.error("Cannot publish report - No signed in user")
            return 
        }
        var event = JSONEvent(
            pubKey: keyPair.publicKeyHex, 
            kind: .report, 
            tags: [
                ["L", "MOD"],
                ["l", selectedCategory.code, "MOD"],
            ], 
            content: "This report uses NIP-69 vocabulary https://github.com/nostr-protocol/nips/pull/457"
        )
        
        var targetTag = reportedObject.tag
        targetTag.append(selectedCategory.nip56Code.rawValue)
        event.tags.append(targetTag)
        
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
    
    static var previews: some View {
        StatefulPreviewContainer(false) { binding in
            VStack {
                Button("Report this") { 
                    binding.wrappedValue.toggle()
                }
                .reportMenu(binding, reportedObject: .note(PreviewData.imageNote))
            }
        }
    }
}
