//
//  ThreadView.swift
//  Nos
//
//  Created by Matthew Lorentz on 2/14/23.
//

import SwiftUI
import SwiftUINavigation

struct RepliesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject private var relayService: RelayService
    @EnvironmentObject var router: Router

    @State private var reply = ""
    
    @State private var alert: AlertState<Never>?
    
    var repliesRequest: FetchRequest<Event>
    var replies: FetchedResults<Event> { repliesRequest.wrappedValue }
    
    var directReplies: [Event] {
        replies.filter { ($0.eventReferences?.lastObject as? EventReference)?.eventId == note.identifier }
    }
    
    init(note: Event) {
        self.note = note
        
        if let rootReference = (note.eventReferences?.array as? [EventReference])?
            .first(where: { $0.marker == "root" }),
            let rootId = rootReference.eventId {
            self.repliesRequest = FetchRequest(fetchRequest: Event.allReplies(toEventWith: rootId))
        } else {
            self.repliesRequest = FetchRequest(fetchRequest: Event.allReplies(to: note))
        }
    }
    
    private var keyPair: KeyPair? {
        KeyPair.loadFromKeychain()
    }
    
    var note: Event
    
    var body: some View {
        VStack {
            ScrollView(.vertical) {
                LazyVStack {
                    NoteButton(note: note)
                        .padding(.horizontal)
                    ForEach(directReplies.reversed()) { event in
                        ThreadView(root: event, allReplies: replies.reversed())
                    }
                }
                .padding(.bottom)
            }
            .padding(.top, 1)
            .navigationBarBackButtonHidden(true)
            .onAppear {
                router.navigationTitle = Localized.threadView.rawValue
            }
            VStack {
                Spacer()
                VStack {
                    ExpandingTextFieldAndSubmitButton( placeholder: "Post a reply", reply: $reply) {
                        postReply(reply)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
                .background(Color.white)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    func postReply(_ replyText: String) {
        do {
            guard let keyPair else {
                alert = AlertState(title: {
                    TextState(Localized.error.string)
                }, message: {
                    TextState(Localized.youNeedToEnterAPrivateKeyBeforePosting.string)
                })
                return
            }
            
            var tags: [[String]] = [["p", note.author!.publicKey!.hex]]
            if note.eventReferences?.count ?? 0 > 0 {
                if let referenceArray = note.eventReferences?.array as? [EventReference],
                    let firstReference = referenceArray.first {
                    if let rootReference = referenceArray.first(where: { $0.marker == "root" }) {
                        tags.append(["e", rootReference.eventId ?? "", "", "root"])
                        tags.append(["e", note.identifier!, "", "reply"])
                    } else {
                        tags.append(["e", firstReference.eventId ?? "", "", "reply"])
                    }
                }
            } else {
                tags.append(["e", note.identifier!, "", "root"])
            }
            // print("tags: \(tags)")
            let jsonEvent = JSONEvent(
                id: "",
                pubKey: keyPair.publicKeyHex,
                createdAt: Int64(Date().timeIntervalSince1970),
                kind: 1,
                tags: tags,
                content: replyText,
                signature: ""
            )
            if let event = Event.findOrCreate(jsonEvent: jsonEvent, context: viewContext) {
                
                try event.sign(withKey: keyPair)
                try relayService.publish(event)
            }
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
struct RepliesView_Previews: PreviewProvider {
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
                RepliesView(note: shortNote)
            }
            VStack {
                RepliesView(note: longNote)
            }
        }
        .padding()
        .background(Color.cardBackground)
    }
}
