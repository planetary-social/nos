//
//  ThreadView.swift
//  Nos
//
//  Created by Matthew Lorentz on 2/14/23.
//

import SwiftUI

struct ThreadView: View {
    @EnvironmentObject var router: Router

    @State private var authorsToSync: [Author] = []
    
    var repliesRequest: FetchRequest<Event>
    var replies: FetchedResults<Event> { repliesRequest.wrappedValue }
    
    init(note: Event) {
        self.note = note
        self.repliesRequest = FetchRequest(fetchRequest: Event.allRepliesAndRoot(to: note), animation: .default)
    }
    
    var note: Event
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack {
                ForEach(replies.reversed()) { event in
                    VStack {
                        NoteButton(note: event)
                            .padding(.horizontal)
                    }
                    .onAppear {
                        // Error scenario: we have an event in core data without an author
                        guard let author = event.author else {
                            print("Event author is nil")
                            return
                        }
                        
                        if !author.isPopulated {
                            print("Need to sync author: \(author.hexadecimalPublicKey ?? "")")
                            authorsToSync.append(author)
                        }
                    }
                }
            }
        }
        .padding(.top, 1)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            router.navigationTitle = Localized.threadView.rawValue
        }
    }
}

struct ThreadView_Previews: PreviewProvider {
    static var persistenceController = PersistenceController.preview
    static var previewContext = persistenceController.container.viewContext
    
    static var shortNote: Event {
        let note = Event(context: previewContext)
        note.content = "Hello, world!"
        return note
    }
    
    static var longNote: Event {
        let note = Event(context: previewContext)
        note.content = .loremIpsum(5)
        return note
    }
    
    static var previews: some View {
        Group {
            VStack {
                ThreadView(note: shortNote)
            }
            VStack {
                ThreadView(note: longNote)
            }
        }
        .padding()
        .background(Color.cardBackground)
    }
}

