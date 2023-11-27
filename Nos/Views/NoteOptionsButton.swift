//
//  NoteOptionsButton.swift
//  Nos
//
//  Created by Jason Cheatham on 3/6/23.
//

import Foundation
import SwiftUI
import Dependencies

struct NoteOptionsButton: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var currentUser: CurrentUser
    
    @Dependency(\.analytics) private var analytics
    @Dependency(\.persistenceController) private var persistenceController
    
    var note: Event

    @State private var showingOptions = false
    @State private var showingShare = false
    @State private var showingSource = false
    @State private var showingReportMenu = false
    @State private var confirmDelete = false

    var body: some View {
        VStack {
            Button {
                showingOptions = true
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondaryText)
                    .frame(minWidth: 44, minHeight: 44)
                    // This hack fixes a weird issue where the confirmationDialog wouldn't be shown sometimes. ¯\_(ツ)_/¯
                    .background(showingOptions == true ? .clear : .clear)
            }
            .confirmationDialog(Localized.share.string, isPresented: $showingOptions) {
                Button(Localized.copyNoteIdentifier.string) {
                    analytics.copiedNoteIdentifier()
                    copyMessageIdentifier()
                }
                Button(Localized.copyNoteText.string) {
                    analytics.copiedNoteText()
                    copyMessage()
                }
                Button(Localized.copyLink.string) {
                    analytics.copiedNoteLink()
                    copyLink()
                }
                Button(Localized.viewSource.string) {
                    analytics.viewedNoteSource()
                    showingSource = true
                }
                Button(Localized.reportNote.string, role: .destructive) {
                    showingReportMenu = true
                }
                if note.author == currentUser.author {
                    Button(Localized.deleteNote.string, role: .destructive) {
                        confirmDelete = true
                    }
                }
            }
            .reportMenu($showingReportMenu, reportedObject: .note(note))
            .alert(
                Localized.confirmReport.string,
                isPresented: $confirmDelete,
                actions: {
                    Button(Localized.confirm.string, role: .destructive) {
                        analytics.deletedNote()
                        Task { await deletePost() }
                    }
                    Button(Localized.cancel.string, role: .cancel) {
                        confirmDelete = false
                    }
                },
                message: {
                    Localized.deleteNoteConfirmation.view
                }
            )
            .sheet(isPresented: $showingSource) {
                NavigationView {
                    RawEventView(viewModel: RawEventController(note: note, dismissHandler: {
                        showingSource = false
                    }))
                }
            }
            .sheet(isPresented: $showingShare) {
            }
        }
    }
    
    func copyMessageIdentifier() {
        UIPasteboard.general.string = note.bech32NoteID
    }
    
    func copyLink() {
        UIPasteboard.general.string = note.webLink
    }
    
    func copyMessage() {
        Task {
            // TODO: put links back in
            let attrString = await Event.attributedContent(
                noteID: note.identifier, 
                context: persistenceController.viewContext
            ) 
            UIPasteboard.general.string = String(attrString.characters)
        }
    }
    
    func deletePost() async {
        if let identifier = note.identifier {
            await currentUser.publishDelete(for: [identifier])
        }
    }
}

struct NoteOptionsView_Previews: PreviewProvider {
    static var previewData = PreviewData()
    static var persistenceController = PersistenceController.preview
    static var previewContext = persistenceController.container.viewContext
    static var relayService = previewData.relayService
    static var currentUser = previewData.currentUser
    
    static var shortNote: Event {
        let note = Event(context: previewContext)
        note.content = "Hello, world!"
        return note
    }
    
    static let note: Event = {
        var note = shortNote
        return note
    }()

    static var previews: some View {
        Group {
            NoteOptionsButton(note: note)
            NoteOptionsButton(note: note)
                .preferredColorScheme(.dark)
        }
        .padding()
        .background(Color.cardBackground)
        .environmentObject(currentUser)
    }
}
