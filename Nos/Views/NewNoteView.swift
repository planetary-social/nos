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
    
    @State private var postText: String = ""
    
    @State private var alert: AlertState<Never>?
    
    @State private var showRelayPicker = false
    @State private var selectedRelay: Relay?

    @Binding var isPresented: Bool
    
    enum FocusedField {
        case textEditor
    }
    
    @FocusState private var focusedField: FocusedField?

    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    Form {
                        TextEditor(text: $postText)
                            .frame(maxHeight: .infinity)
                            .placeholder(when: postText.isEmpty, placeholder: {
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
                    .disabled(postText.isEmpty)
                    .padding(.bottom, 3)
            )
            .onAppear {
                focusedField = .textEditor
                analytics.showedNewNote()
            }
        }
        .alert(unwrapping: $alert)
    }
    
    private func publishPost() async {
        guard let keyPair = currentUser.keyPair else {
            alert = AlertState(title: {
                TextState(Localized.error.string)
            }, message: {
                TextState(Localized.youNeedToEnterAPrivateKeyBeforePosting.string)
            })
            return
        }
        
        do {
            let jsonEvent = JSONEvent(
                id: "",
                pubKey: keyPair.publicKeyHex,
                createdAt: Int64(Date().timeIntervalSince1970),
                kind: 1,
                tags: [],
                content: postText,
                signature: ""
            )
            
            if let selectedRelay {
                try await relayService.publish(
                    event: jsonEvent,
                    to: selectedRelay,
                    signingKey: keyPair,
                    context: viewContext
                )
            } else {
                try await relayService.publishToAll(event: jsonEvent, signingKey: keyPair, context: viewContext)
            }
            isPresented = false
            analytics.published(note: jsonEvent)
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
