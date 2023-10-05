//
//  AuthorStoryView.swift
//  Nos
//
//  Created by Matthew Lorentz on 3/23/23.
//

import SwiftUI
import CoreData

struct AuthorStoryView: View {
    
    var author: Author
    var showNextAuthor: () -> Void
    var showPreviousAuthor: () -> Void
    
    @FetchRequest private var notes: FetchedResults<Event>

    @State private var selectedNote: Event?

    @State private var offset: Int = 0

    @Binding private var cutoffDate: Date

    @EnvironmentObject private var router: Router
    @Environment(\.managedObjectContext) private var viewContext
    
    init(author: Author, cutoffDate: Binding<Date>, showPreviousAuthor: @escaping () -> Void, showNextAuthor: @escaping () -> Void) {
        self.author = author
        self._cutoffDate = cutoffDate
        self.showPreviousAuthor = showPreviousAuthor
        self.showNextAuthor = showNextAuthor
        _notes = FetchRequest(fetchRequest: author.storiesRequest(since: cutoffDate.wrappedValue))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: false) {
                Group {
                    if let selectedNote {
                        CompactNoteView(note: selectedNote, showFullMessage: false)
                            .padding(.top, 60)
                    } else {
                        EmptyView()
                    }
                }
            }
            .id(selectedNote)
            .onTapGesture { point in
                guard let selectedNote, let selectedNoteIndex = notes.firstIndex(of: selectedNote) else {
                    return
                }
                if point.x < 100 {
                    if selectedNoteIndex > 0 {
                        let previousIndex = notes.index(before: selectedNoteIndex)
                        self.selectedNote = notes[safe: previousIndex]
                    } else {
                        showPreviousAuthor()
                    }
                } else if point.x > geometry.size.width - 100 {
                    if selectedNoteIndex < notes.count - 1 {
                        let nextIndex = notes.index(after: selectedNoteIndex)
                        self.selectedNote = notes[safe: nextIndex]
                    } else {
                        showNextAuthor()
                    }
                }
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
                                    .foregroundColor(note.isEqual(selectedNote) == true ? .accent : .secondaryText)
                                    .padding(.bottom, 5)
                                    .padding(.top, 15)
                            }
                        }
                    }
                    .padding(.horizontal, 10)

                    Button {
                        router.push(author)
                    } label: {
                        HStack(alignment: .center) {
                            AuthorLabel(author: author)
                                .padding(0)
                            if let elapsedTime = selectedNote?.createdAt?.elapsedTimeFromNowString() {
                                Text(elapsedTime)
                                    .lineLimit(1)
                                    .font(.body)
                                    .foregroundColor(.secondaryText)
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
                        colors: [Color.appBg.opacity(1), Color.appBg.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
        }
        .task {
            if selectedNote == nil {
                if let firstNote = notes.first {
                    selectedNote = firstNote
                } else {
                    // TODO: this is a temporary hack. We should be filtering out authors with no root posts in the database query, not here.
                    showNextAuthor()
                }
            }
        }
    }
}

struct AuthorStoryView_Previews: PreviewProvider {
    
    static var previewData = PreviewData()
    @State static var cutoffDate = Calendar.current.date(byAdding: .day, value: -14, to: .now)!
    
    static var previews: some View {
        NavigationView {
            AuthorStoryView(author: previewData.bob, cutoffDate: $cutoffDate, showPreviousAuthor: {}, showNextAuthor: {})
        }
        .inject(previewData: previewData)
    }
}
