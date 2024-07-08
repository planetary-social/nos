import Dependencies
import SwiftUI
import CoreData

/// Displays a list of stories for a given Author
struct AuthorStoryView: View {
    
    var author: Author
    var showNextAuthor: () -> Void
    var showPreviousAuthor: () -> Void

    /// The list of stories to present
    @FetchRequest private var notes: FetchedResults<Event>

    /// The note currently being shown
    @State private var selectedNote: Event?

    @Binding private var cutoffDate: Date

    @State private var relaySubscriptions = SubscriptionCancellables()

    @EnvironmentObject private var router: Router
    @EnvironmentObject private var relayService: RelayService
    @ObservationIgnored @Dependency(\.analytics) private var analytics

    init(
        author: Author,
        cutoffDate: Binding<Date>,
        showPreviousAuthor: @escaping () -> Void,
        showNextAuthor: @escaping () -> Void
    ) {
        self.author = author
        self.showPreviousAuthor = showPreviousAuthor
        self.showNextAuthor = showNextAuthor
        _cutoffDate = cutoffDate
        _notes = FetchRequest(fetchRequest: author.storiesRequest(since: cutoffDate.wrappedValue))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: false) {
                Group {
                    if let selectedNote {
                        StoryNoteView(note: selectedNote, minHeight: geometry.size.height - 40)
                    } else {
                        EmptyView()
                    }
                }
            }
        }
        .id(selectedNote)
        .overlay(alignment: .leading) {
            Button {
                guard let selectedNote, let selectedNoteIndex = notes.firstIndex(of: selectedNote) else {
                    return
                }
                if selectedNoteIndex > 0 {
                    let previousIndex = notes.index(before: selectedNoteIndex)
                    self.selectedNote = notes[safe: previousIndex]
                } else {
                    showPreviousAuthor()
                }
            } label: {
                Color.red.opacity(0)
            }
            .frame(maxWidth: 60, maxHeight: .infinity)
        }
        .overlay(alignment: .trailing) {
            Button {
                guard let selectedNote, let selectedNoteIndex = notes.firstIndex(of: selectedNote) else {
                    return
                }
                if selectedNoteIndex < notes.count - 1 {
                    let nextIndex = notes.index(after: selectedNoteIndex)
                    self.selectedNote = notes[safe: nextIndex]
                } else {
                    showNextAuthor()
                }
            } label: {
                Color.green.opacity(0)
            }
            .frame(maxWidth: 60, maxHeight: .infinity)
        }
        .overlay(alignment: .topLeading) {
            VStack {
                HStack(spacing: 6) {
                    ForEach(notes) { note in
                        Button {
                            selectedNote = note
                        } label: {
                            RoundedRectangle(cornerRadius: 21)
                                .frame(maxWidth: .infinity, maxHeight: 3)
                                .cornerRadius(7)
                                .foregroundColor(note.isEqual(selectedNote) == true ? .accent : .secondaryTxt)
                                .padding(.bottom, 5)
                                .padding(.top, 15)
                        }
                    }
                }
                .padding(.horizontal, 10)
                Button {
                    router.push(author)
                    analytics.openedProfileFromStories()
                } label: {
                    HStack(alignment: .center) {
                        AuthorLabel(author: author)
                            .padding(0)
                        if selectedNote?.kind == EventKind.repost.rawValue {
                            Image.repostSymbol
                        } 
                        if let expirationTime = selectedNote?.expirationDate?.distanceString() {
                            Image.disappearingMessages
                                .resizable()
                                .foregroundColor(.secondaryTxt)
                                .frame(width: 25, height: 25)
                            Text(expirationTime)
                                .lineLimit(1)
                                .font(.clarity(.medium))
                                .foregroundColor(.secondaryTxt)
                        } else if let elapsedTime = selectedNote?.createdAt?.distanceString() {
                            Text(elapsedTime)
                                .lineLimit(1)
                                .font(.clarity(.medium))
                                .foregroundColor(.secondaryTxt)
                        }
                        Spacer()
                        if let selectedNote {
                            NoteOptionsButton(note: selectedNote)
                        }
                    }
                    .padding(.leading, 10)
                    .padding(.vertical, 0)
                }
            }
            .padding(.bottom, 10)
            .background {
                LinearGradient(
                    stops: [
                        Gradient.Stop(color: .storiesBgTop.opacity(1), location: 0.25),
                        Gradient.Stop(color: .storiesBgTop.opacity(0), location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .overlay(alignment: .bottomLeading) {
            if let selectedNote, selectedNote.kind != EventKind.repost.rawValue {
                BottomOverlay(note: selectedNote)
            } else {
                EmptyView()
            }
        }
        .task {
            // Select the first note in the fetch results when presenting the view
            guard selectedNote == nil else {
                return
            }
            if let firstUnreadNote = notes.first(where: { !$0.isRead }) {
                selectedNote = firstUnreadNote
            } else if let firstNote = notes.first {
                selectedNote = firstNote
            } else {
                // Notes shouldn't be empty here, but if they are, just advance to the next author
                showNextAuthor()
            }
        }
        .task {
            await subscribeToReplies()
        }
    }

    /// Fetches replies to the list of stories from connected relays (to update reply count to each one)
    private func subscribeToReplies() async {
        // Close out stale requests
        relaySubscriptions.removeAll()
        let eTags = notes.compactMap { $0.identifier }
        guard !eTags.isEmpty else {
            return
        }
        
        let filter = Filter(
            kinds: [.text, .like, .delete, .repost],
            eTags: eTags,
            shouldKeepSubscriptionOpen: true
        )
        relaySubscriptions.append(
            await relayService.fetchEvents(matching: filter)
        )
    }
}

fileprivate struct BottomOverlay: View {
    
    var note: Event

    @Dependency(\.persistenceController) private var persistenceController

    @EnvironmentObject private var router: Router

    var body: some View {
        HStack(spacing: 0) {
            RepliesLabel(repliesDisplayType: .discussion, for: note)

            Spacer()

            RepostButton(note: note)

            LikeButton(note: note)

            ReplyButton(note: note)
        }
        .padding(.leading, 13)
        .padding(.bottom, 10)
        .background {
            LinearGradient(
                stops: [
                    Gradient.Stop(color: .storiesBgBottom.opacity(0), location: 0),
                    Gradient.Stop(color: .storiesBgBottom.opacity(1), location: 0.75),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}
struct AuthorStoryView_Previews: PreviewProvider {
    
    static var previewData = PreviewData()
    @State static var cutoffDate = Calendar.current.date(byAdding: .day, value: -14, to: .now)!
    
    static var previews: some View {
        NavigationView {
            AuthorStoryView(
                author: previewData.bob,
                cutoffDate: $cutoffDate,
                showPreviousAuthor: {},
                showNextAuthor: {}
            )
        }
        .inject(previewData: previewData)
    }
}
