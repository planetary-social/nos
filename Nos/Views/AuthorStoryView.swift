//
//  AuthorStoryView.swift
//  Nos
//
//  Created by Matthew Lorentz on 3/23/23.
//

import SwiftUI
import CoreData

struct AuthorStoryView: View {
    
    @ObservedObject var author: Author
    var showNextAuthor: () -> Void
    var showPreviousAuthor: () -> Void
    
    @FetchRequest private var notes: FetchedResults<Event>

    @State private var selectedNoteIndex: Int = 0

    @Binding private var cutoffDate: Date
    
    init(author: Author, cutoffDate: Binding<Date>, showPreviousAuthor: @escaping () -> Void, showNextAuthor: @escaping () -> Void) {
        self.author = author
        self._cutoffDate = cutoffDate
        self.showPreviousAuthor = showPreviousAuthor
        self.showNextAuthor = showNextAuthor
        _notes = FetchRequest(fetchRequest: author.storiesRequest(since: cutoffDate.wrappedValue))
    }
    
    var body: some View {
        TabView(selection: $selectedNoteIndex) {
            ForEach(notes.indices) { noteIndex in
                ScrollView(.vertical, showsIndicators: false) {
                    CompactNoteView(note: notes[noteIndex], showFullMessage: false)
                        .padding(.top, 40)
                }
                .tag(noteIndex)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .overlay(alignment: .topLeading) {
            VStack {
                HStack(spacing: 6) {
                    ForEach(notes.indices) { noteIndex in
                        let isSelected = noteIndex == selectedNoteIndex
                        RoundedRectangle(cornerRadius: 21)
                            .frame(maxWidth: .infinity, maxHeight: 3)
                            .cornerRadius(7)
                            .foregroundColor(isSelected ? .accent : .secondaryText)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 5)

                Button {

                } label: {
                    HStack(alignment: .center) {
                        AuthorLabel(author: author, note: nil)
                            .padding(0)
                        if let elapsedTime = notes[safe: selectedNoteIndex]?.createdAt?.elapsedTimeFromNowString() {
                            Text(elapsedTime)
                                .lineLimit(1)
                                .font(.body)
                                .foregroundColor(.secondaryText)
                        }
                        Spacer()
                        if let note = notes[safe: selectedNoteIndex] {
                            NoteOptionsButton(note: note)
                        }
                    }
                    .padding(.leading, 10)
                    .padding(.vertical, 0)
                }

            }
        }
        .onAppear {
            // TODO: this is a temporary hack. We should be filtering out authors with no root posts in the database query, not here.
            if notes.count == 0 {
                showNextAuthor()
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
