//
//  ThreadView.swift
//  Nos
//
//  Created by Matthew Lorentz on 2/14/23.
//

import SwiftUI

struct ThreadView: View {
    @EnvironmentObject var router: Router
    
    var note: Event
    var body: some View {
        Text("Thread view placeholder for note: \(note.identifier ?? "no id")")
        Text(note.content ?? "")
        .navigationBarBackButtonHidden(true)
        .onAppear {
            router.navigationTitle = "Thread View"
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
