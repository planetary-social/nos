//
//  NewNoteView.swift
//  Nos
//
//  Created by Matthew Lorentz on 2/6/23.
//

import SwiftUI
import CoreData
import SwiftUINavigation
import Dependencies

struct NewNoteView: View {
    private var keyPair: KeyPair? {
        KeyPair.loadFromKeychain()
    }
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject private var relayService: RelayService
    
    @Dependency(\.analytics) private var analytics
    
    @State private var postText: String = ""
    
    @State private var alert: AlertState<Never>?
    
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                TextEditor(text: $postText)
                    .frame(idealHeight: 180)
                Button(action: publishPost) {
                    Localized.publish.view
                }
            }
            .navigationTitle(Localized.newNote.string)
            .toolbar(content: {
                ToolbarItem {
                    Button {
                        isPresented = false
                    }
                    label: {
                        Localized.cancel.view
                    }
                }
            })
        }
        .alert(unwrapping: $alert)
    }
    
    private func publishPost() {
        guard let keyPair else {
            alert = AlertState(title: {
                TextState(Localized.error.string)
            }, message: {
                TextState(Localized.youNeedToEnterAPrivateKeyBeforePosting.string)
            })
            return
        }
        
        withAnimation {
            do {
                let event = Event(context: viewContext)
                event.createdAt = Date()
                event.content = postText
                event.kind = 1
                event.author = try Author.findOrCreate(by: keyPair.publicKeyHex, context: viewContext)

                try event.sign(withKey: keyPair)
                relayService.publishToAll(event: event)
                isPresented = false
                analytics.published(note: event)
            } catch {
                alert = AlertState(title: {
                    TextState(Localized.error.string)
                }, message: {
                    TextState(error.localizedDescription)
                })
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this
                // function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct NewPostView_Previews: PreviewProvider {
    
    static var persistenceController = PersistenceController.preview
    static var previewContext = persistenceController.container.viewContext
    static var relayService = RelayService(persistenceController: persistenceController)
    
    static var previews: some View {
        NewNoteView(isPresented: .constant(true))
            .environment(\.managedObjectContext, previewContext)
            .environmentObject(relayService)
    }
}
