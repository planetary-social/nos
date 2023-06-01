//
//  ReportMenu.swift
//  Nos
//
//  Created by Matthew Lorentz on 5/24/23.
//

import SwiftUI

struct ReportMenuModifier: ViewModifier {
    
    @Binding var isPresented: Bool
    
    var reportedObject: ReportTarget
    
    @State private var selectedCategory: ReportCategory?
    @State private var confirmReport = false
    @State private var showMuteDialog = false
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var relayService: RelayService
    @EnvironmentObject private var currentUser: CurrentUser
    
    func body(content: Content) -> some View {
        content
            .confirmationDialog("Report Content", isPresented: $isPresented, titleVisibility: .visible) {
                if let selectedCategory {
                    subCategoryButtons(for: selectedCategory.subCategories ?? [])
                } else {
                    subCategoryButtons(for: topLevelCategories)
                }
            }
            .alert(
                "Confirm Report", 
                isPresented: $confirmReport,
                actions: { 
                    Button("Confirm") { 
                        publishReport()
                        showMuteDialog = true
                    }
                    Button("Cancel", role: .cancel) { 
                        selectedCategory = nil
                    }
                },
                message: {
                    // TODO: show what is being reported and why
                    Text("This will publish a report that is publicly visible. Are you sure?")
                }
            ) 
            .alert(
                "Mute User", 
                isPresented: $showMuteDialog,
                actions: { 
                    Button("Yes") { 
                        print("user muted ")
                    }
                    Button("No") { }
                },
                message: {
                    // TODO: handle nil author
                    Text("Would you like to mute \(reportedObject.author!.safeName)?")
                }
            ) 
    }
    
    func subCategoryButtons(for categories: [ReportCategory]) -> some View {
        ForEach(categories) { subCategory in
            Button(subCategory.displayName) { 
                self.selectedCategory = subCategory
                if subCategory.subCategories?.count ?? 0 == 0 {
                    confirmReport = true
                } else {
                    Task { 
                        self.isPresented = true
                    }
                }
            }
        }
    }
    
    func publishReport() {
        guard let keyPair = currentUser.keyPair,
            let selectedCategory else {
            // TODO: show error
            return 
        }
        print("user published report for \(selectedCategory.displayName)")
        let event = JSONEvent(
            pubKey: keyPair.publicKeyHex, 
            kind: .label, 
            tags: [
                ["L", "MOD"],
                ["l", selectedCategory.code, "MOD"],
            ], 
            content: ""
        )
        
        Task {
            do {
                try await relayService.publishToAll(event: event, signingKey: keyPair, context: viewContext)
            } catch {
                // TODO: handle error
            }
        }
    }
}

extension View {
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
                .reportMenu(binding, reportedObject: .event(PreviewData.imageNote))
            }
        }
    }
}
