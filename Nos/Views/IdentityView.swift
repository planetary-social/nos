//
//  IdentityView.swift
//  Nos
//
//  Created by Matthew Lorentz on 2/16/23.
//

import SwiftUI
import CoreData

struct IdentityView: View {
    
    var author: Author
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest
    private var events: FetchedResults<Event>
    
    init(author: Author) {
        self.author = author
        _events = FetchRequest(fetchRequest: author.allPostsRequest())
    }
    
    var body: some View {
        VStack {
            IdentityHeaderView(identity: author)
            List {
                ForEach(events) { event in
                    VStack {
                        NoteCard(note: event)
                    }
                }
            }
            .overlay(Group {
                if events.isEmpty {
                    Localized.noEventsOnProfile.view
                        .padding()
                }
            })
        }
        .background(Color.cardBackground)
        .navigationTitle(Localized.profile.string)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct IdentityView_Previews: PreviewProvider {
    
    static var persistenceController = PersistenceController.preview
    static var previewContext = persistenceController.container.viewContext
    
    static var author: Author = {
        let author = try! Author.findOrCreate(
            by: "d0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e",
            context: previewContext
        )
        // TODO: derive from private key
//        author.name = "Fred"
//        author.about = "Reach for the stars. Someday you just might catch one."
//        try! previewContext.save()
        return author
    }()
    
    static var previews: some View {
        NavigationStack {
            IdentityView(author: author)
        }
        .environment(\.managedObjectContext, previewContext)
    }
}
