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
            .confirmationDialog("share", isPresented: $showingOptions) {
                Button("copyNoteIdentifier") {
                    analytics.copiedNoteIdentifier()
                    copyMessageIdentifier()
                }
                Button("shareNote") {
                    showingShare = true
                    analytics.sharedNoteLink()
                }
                if !note.isStub {
                    Button("copyNoteText") {
                        analytics.copiedNoteText()
                        copyMessage()
                    }
                    Button("viewSource") {
                        analytics.viewedNoteSource()
                        showingSource = true
                    }
                    if note.author != currentUser.author {
                        Button("reportNote") {
                            showingReportMenu = true
                        }
                    }
                }
                if note.author == currentUser.author {
                    Button("deleteNote", role: .destructive) {
                        confirmDelete = true
                    }
                }
            }
            .reportMenu($showingReportMenu, reportedObject: .note(note))
            .alert(
                "confirmDelete",
                isPresented: $confirmDelete,
                actions: {
                    Button("confirm", role: .destructive) {
                        analytics.deletedNote()
                        Task { await deletePost() }
                    }
                    Button("cancel", role: .cancel) {
                        confirmDelete = false
                    }
                },
                message: {
                    Text("deleteNoteConfirmation")
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
                let url = note.webLink
                ActivityViewController(activityItems: [url]) {
                    showingShare = false
                }
            }
        }
    }
    
    private func copyMessageIdentifier() {
        UIPasteboard.general.string = note.bech32NoteID
    }
    
    private func copyMessage() {
        Task {
            // TODO: put links back in
            let attrString = await Event.attributedContent(
                noteID: note.identifier, 
                context: persistenceController.viewContext
            ) 
            UIPasteboard.general.string = String(attrString.characters)
        }
    }
    
    private func deletePost() async {
        if let identifier = note.identifier {
            await currentUser.publishDelete(for: [identifier])
        }
    }
}

struct NoteOptionsButton_Previews: PreviewProvider {
    static var previewData = PreviewData()
    static var persistenceController = PersistenceController.preview
    static var previewContext = persistenceController.viewContext
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
