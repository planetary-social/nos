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
    
    @State private var currentNote: Event?
    
    init(author: Author, showPreviousAuthor: @escaping () -> Void, showNextAuthor: @escaping () -> Void) {
        self.author = author
        self.showPreviousAuthor = showPreviousAuthor
        self.showNextAuthor = showNextAuthor
        _notes = FetchRequest(fetchRequest: author.storiesRequest())
    }
    
    var body: some View {
        VStack {
            // hack
            let _ = handleNotesChanged(to: notes)
            Spacer()
            if let note = currentNote ?? notes.first {
                NoteButton(
                    note: note,
                    showFullMessage: true,
                    hideOutOfNetwork: false
                ) { note in
                    if let currentNoteIndex = notes.firstIndex(of: note) {
                        let nextNoteIndex = notes.index(after: currentNoteIndex)
                        currentNote = notes[nextNoteIndex]
                    } else {
                        currentNote = nil
                    }
                }
                .allowsHitTesting(false)
                .padding()
            } else {
                Text("empty")
            }
            Spacer()
            HStack {
                if let currentNote,
                    let currentNoteIndex = notes.firstIndex(of: currentNote) {
                    ForEach(notes.indices) { noteIndex in
                        RoundedRectangle(cornerRadius: 21)
                            .frame(maxWidth: .infinity, maxHeight: 3)
                            .padding(1.5)
                            .cornerRadius(21)
                            .foregroundColor(noteIndex <= currentNoteIndex ? .accent : .secondaryText)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 15)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            if let currentNote,
                let currentNoteIndex = notes.firstIndex(of: currentNote) {
                let nextNoteIndex = notes.index(after: currentNoteIndex)
                self.currentNote = notes[nextNoteIndex]
            } else {
                currentNote = nil
            }
        }
        .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onEnded({ value in
                if value.translation.width < 0 {
                    showNextAuthor()
                }
                
                if value.translation.width > 0 {
                    showPreviousAuthor()
                }
            }))
        
    }
    
    func handleNotesChanged(to notes: FetchedResults<Event>) {
        Task {
            if notes.isEmpty {
                currentNote = nil
            } else if currentNote == nil {
                currentNote = notes.first
            }
        }
    }
}

struct AuthorStoryView_Previews: PreviewProvider {
    
    static var previewData = PreviewData()
    
    static var previews: some View {
        NavigationView {
            AuthorStoryView(author: previewData.bob, showPreviousAuthor: {}, showNextAuthor: {})
        }
        .inject(previewData: previewData)
    }
}
