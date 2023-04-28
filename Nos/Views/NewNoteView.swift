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
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var relayService: RelayService
    @EnvironmentObject var currentUser: CurrentUser
    @EnvironmentObject private var router: Router
    @Dependency(\.analytics) private var analytics

    /// State holding the text the user is typing
    @State private var postText = AttributedString("")

    /// State containing the offset (index) of text when the user is mentioning someone
    ///
    /// When we detect the user typed a '@', we save the position of that character here and open a screen
    /// that lets the user select someone to mention, then we can replace this character with the full mention.
    @State private var mentionOffset: Int?

    /// State containing the very last state before `text` changes
    ///
    /// We need this so that we can compare and decide what has changed.
    @State private var oldText: String = ""
    
    @State private var alert: AlertState<Never>?
    
    @State private var showRelayPicker = false
    @State private var selectedRelay: Relay?

    @Binding var isPresented: Bool
    
    enum FocusedField {
        case textEditor
    }
    
    @FocusState private var focusedField: FocusedField?

    /// Setting this to true will pop up the mention list to select an author to mention in the text editor.
    private var showAvailableMentions: Binding<Bool> {
        Binding {
            mentionOffset != nil
        } set: { _ in
            mentionOffset = nil
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    Form {
                        EditableText($postText)
                            .frame(maxHeight: .infinity)
                            .placeholder(when: postText.characters.isEmpty, placeholder: {
                                VStack {
                                    Text("Type your post here...")
                                        .foregroundColor(.secondaryTxt)
                                        .padding(.horizontal, 8.5)
                                        .padding(.vertical, 10)
                                    Spacer()
                                }
                            })
                            .listRowBackground(Color.appBg)
                            .focused($focusedField, equals: .textEditor)
                            .onChange(of: postText) { newValue in
                                let newText = String(newValue.characters)
                                let difference = newText.difference(from: oldText)
                                guard difference.count == 1, let change = difference.first else {
                                    oldText = newText
                                    return
                                }
                                switch change {
                                case .insert(let offset, let element, _):
                                    if element == "@" {
                                        mentionOffset = offset
                                    }
                                default:
                                    break
                                }
                                oldText = newText
                            }
                            .sheet(isPresented: showAvailableMentions) {
                                NavigationStack {
                                    AuthorListView { author in
                                        guard let offset = mentionOffset else {
                                            return
                                        }
                                        insertMention(at: offset, author: author)
                                    }
                                }
                                .presentationDetents([.medium, .large])
                            }
                    }
                    Spacer()
                    HStack {
                        HighlightedText(
                            Localized.nostrBuildHelp.string,
                            highlightedWord: "nostr.build",
                            highlight: .diagonalAccent,
                            textColor: .secondaryTxt,
                            link: URL(string: "https://nostr.build")!
                        )
                        .listRowBackground(Color.appBg)
                        .listRowSeparator(.hidden)
                        .padding(.leading, 17)
                        .padding(10)
                        Spacer()
                    }
                }
                .scrollContentBackground(.hidden)
                
                if showRelayPicker, let author = currentUser.author {
                    RelayPicker(
                        selectedRelay: $selectedRelay,
                        defaultSelection: Localized.extendedNetwork.string,
                        author: author,
                        isPresented: $showRelayPicker
                    )
                    .onChange(of: selectedRelay) { _ in
                        withAnimation {
                            showRelayPicker = false
                        }
                    }
                }
            }
            .background(Color.appBg)
            .navigationBarTitle(Localized.newNote.string, displayMode: .inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.cardBgBottom, for: .navigationBar)
            .toolbar {
                RelayPickerToolbarButton(
                    selectedRelay: $selectedRelay,
                    isPresenting: $showRelayPicker,
                    defaultSelection: Localized.allMyRelays
                ) {
                    withAnimation {
                        showRelayPicker.toggle()
                    }
                }
            }
            .navigationBarItems(
                leading: Button {
                    isPresented = false
                    UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.endEditing(true)
                }
                label: {
                    Localized.cancel.view
                        .foregroundColor(.textColor)
                },
                trailing: ActionButton(title: Localized.post, action: publishPost)
                    .frame(height: 22)
                    .disabled(postText.characters.isEmpty)
                    .padding(.bottom, 3)
            )
            .onAppear {
                focusedField = .textEditor
                analytics.showedNewNote()
            }
        }
        .alert(unwrapping: $alert)
    }

    private func insertMention(at offset: Int, author: Author) {
        NotificationCenter.default.post(
            name: .mentionAddedNotification,
            object: nil,
            userInfo: ["author": author]
        )
        oldText = String(postText.characters)
        mentionOffset = nil
    }
    
    private func publishPost() {
        guard let keyPair = currentUser.keyPair else {
            alert = AlertState(title: {
                TextState(Localized.error.string)
            }, message: {
                TextState(Localized.youNeedToEnterAPrivateKeyBeforePosting.string)
            })
            return
        }
        
        withAnimation {
            do {
                let parser = NoteParser()
                let (content, tags) = parser.parse(attributedText: postText)
                let jsonEvent = JSONEvent(
                    id: "",
                    pubKey: keyPair.publicKeyHex,
                    createdAt: Int64(Date().timeIntervalSince1970),
                    kind: 1,
                    tags: tags,
                    content: content,
                    signature: ""
                )
                let event = try Event.findOrCreate(jsonEvent: jsonEvent, relay: nil, context: viewContext)
                event.author = try Author.findOrCreate(by: keyPair.publicKeyHex, context: viewContext)

                try event.sign(withKey: keyPair)
                try viewContext.save()
                if let selectedRelay {
                    relayService.publish(to: selectedRelay, event: event, context: viewContext)
                } else {
                    relayService.publishToAll(event: event, context: viewContext)
                }
                isPresented = false
                analytics.published(note: event)
                postText = ""
                router.selectedTab = .home
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
