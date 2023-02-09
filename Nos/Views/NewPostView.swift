//
//  NewPostView.swift
//  Nos
//
//  Created by Matthew Lorentz on 2/6/23.
//

import SwiftUI
import CoreData
import SwiftUINavigation

struct NewPostView: View {
    
    @AppStorage("keyPair") private var keyPair: KeyPair?
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject private var relayService: RelayService
    
    @State private var postText: String = ""
    
    @State private var alert: AlertState<Never>?
    
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                TextEditor(text: $postText)
                    .frame(idealHeight: 180)
                Button(action: publishPost) {
                    Text("Publish")
                }
            }
            .navigationTitle("New Post")
            .toolbar(content: {
                ToolbarItem() {
                    Button(action: { isPresented = false }) {
                        Text("Cancel")
                    }
                }
            })
        }
        .alert(unwrapping: $alert)
    }
    
    private func publishPost() {
        guard let keyPair else {
            alert = AlertState(title: {
                TextState("Error")
            }, message: {
                TextState("You need to enter a private key in Settings before you can publish posts.")
            })
            return
        }
        
        withAnimation {
            let event = Event(context: viewContext)
            event.createdAt = Date()
            event.content = postText
            event.kind = 1
            
            let author = Author(context: viewContext)
            // TODO: derive from private key
            author.hexadecimalPublicKey = "32730e9dfcab797caf8380d096e548d9ef98f3af3000542f9271a91a9e3b0001"
            event.author = author
            

            do {
                try event.sign(withKey: keyPair)
                try relayService.publish(event)
                isPresented = false
            } catch {
                alert = AlertState(title: {
                    TextState("Error")
                }, message: {
                    TextState(error.localizedDescription)
                })
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
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
        NewPostView(isPresented: .constant(true))
            .environment(\.managedObjectContext, previewContext)
            .environmentObject(relayService)
    }
}
