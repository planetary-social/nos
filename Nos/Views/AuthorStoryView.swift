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
    
    @State private var noteIndex: Int = 0
    
    init(author: Author, showPreviousAuthor: @escaping () -> Void, showNextAuthor: @escaping () -> Void) {
        self.author = author
        self.showPreviousAuthor = showPreviousAuthor
        self.showNextAuthor = showNextAuthor
        _notes = FetchRequest(fetchRequest: author.storiesRequest())
    }
    
    var body: some View {
        VStack {
            // hack
//            let _ = handleNotesChanged(to: notes)
            Spacer()
            if let note = notes[safe: noteIndex] {
                NoteButton(
                    note: note,
                    showFullMessage: true,
                    hideOutOfNetwork: false
                ) 
                .id(noteIndex) // TODO: Why doesn't it work without this!?
                .allowsHitTesting(false)
                .padding()
            } else {
                Text("empty")
            }
            Spacer()
            HStack {
                if let currentNote = notes[safe: noteIndex] {
                    ForEach(notes.indices) { noteIndex in
                        RoundedRectangle(cornerRadius: 21)
                            .frame(maxWidth: .infinity, maxHeight: 3)
                            .padding(1.5)
                            .cornerRadius(21)
                            .foregroundColor(noteIndex <= self.noteIndex ? .accent : .secondaryText)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 15)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            if let currentNote = notes[safe: noteIndex],
                let currentNoteIndex = notes.firstIndex(of: currentNote),
                currentNoteIndex < max(notes.count - 1, 0) {
                let nextNoteIndex = notes.index(after: currentNoteIndex)
                self.noteIndex = nextNoteIndex
            } else { 
                showNextAuthor() 
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
    
//    func handleNotesChanged(to notes: FetchedResults<Event>) {
//        Task {
//            noteIndex = 0
//        }
//    }
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
