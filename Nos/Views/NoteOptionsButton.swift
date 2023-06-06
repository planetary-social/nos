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
    
    var note: Event

    @State private var showingOptions = false
    @State private var showingShare = false
    @State private var showingSource = false
    @State private var showingReportMenu = false

    var body: some View {
        VStack {
            Button {
                showingOptions = true
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.nosSecondary)
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
//                    Analytics.shared.trackDidSelectAction(actionName: "report_post")
                    showingReportMenu = true
                }
                if note.author == currentUser.author {
                    Button(Localized.deleteNote.string) {
                        analytics.deletedNote()
                        Task { await deletePost() }
                    }
                }
            }
            .reportMenu($showingReportMenu, reportedObject: .note(note))
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
            if let attrString = await Event.attributedContent(
                noteID: note.identifier,
                context: viewContext
            ) {
                UIPasteboard.general.string = String(attrString.characters)
            }
        }
    }
    
    func deletePost() async {
        if let identifier = note.identifier {
            await currentUser.publishDelete(for: [identifier])
        }
    }
}

struct NoteOptionsView_Previews: PreviewProvider {
    static var persistenceController = PersistenceController.preview
    static var previewContext = persistenceController.container.viewContext
    static var relayService = RelayService(persistenceController: persistenceController)

    static var currentUser: CurrentUser = {
        let currentUser = CurrentUser(persistenceController: persistenceController)
        currentUser.viewContext = previewContext
        currentUser.relayService = relayService
        Task { await currentUser.setKeyPair(KeyFixture.keyPair) }
        return currentUser
    }()
    
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
