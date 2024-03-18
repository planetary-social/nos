import Foundation
import SwiftUI
import Dependencies

struct NoteOptionsButton: View {
    @Environment(CurrentUser.self) private var currentUser
    
    @Dependency(\.analytics) private var analytics
    @Dependency(\.persistenceController) private var persistenceController
    
    @ObservedObject var note: Event

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
                    .foregroundColor(.secondaryTxt)
                    .fontWeight(.bold)
                    .frame(minWidth: 44, minHeight: 44)
                    // This hack fixes a weird issue where the confirmationDialog wouldn't be shown sometimes. ¯\_(ツ)_/¯
                    .background(showingOptions == true ? .clear : .clear)
            }
            .confirmationDialog(String(localized: .localizable.share), isPresented: $showingOptions) {
                Button(String(localized: .localizable.copyNoteIdentifier)) {
                    analytics.copiedNoteIdentifier()
                    copyMessageIdentifier()
                }
                Button(String(localized: .localizable.copyLink)) {
                    analytics.copiedNoteLink()
                    copyLink()
                }
                if !note.isStub {
                    Button(String(localized: .localizable.copyNoteText)) {
                        analytics.copiedNoteText()
                        copyMessage()
                    }
                    Button(String(localized: .localizable.viewSource)) {
                        analytics.viewedNoteSource()
                        showingSource = true
                    }
                    Button(String(localized: .localizable.reportNote), role: .destructive) {
                        showingReportMenu = true
                    }
                }
                if note.author == currentUser.author {
                    Button(String(localized: .localizable.deleteNote), role: .destructive) {
                        confirmDelete = true
                    }
                }
            }
            .reportMenu($showingReportMenu, reportedObject: .note(note))
            .alert(
                String(localized: .localizable.confirmReport),
                isPresented: $confirmDelete,
                actions: {
                    Button(String(localized: .localizable.confirm), role: .destructive) {
                        analytics.deletedNote()
                        Task { await deletePost() }
                    }
                    Button(String(localized: .localizable.cancel), role: .cancel) {
                        confirmDelete = false
                    }
                },
                message: {
                    Text(.localizable.deleteNoteConfirmation)
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
        .background(Color.previewBg)
        .environment(currentUser)
    }
}
