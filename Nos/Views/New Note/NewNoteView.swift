//
//  NewNoteView.swift
//  Nos
//
//  Created by Matthew Lorentz on 2/6/23.
//

import CoreData
import Dependencies
import Logger
import SwiftUI
import SwiftUINavigation

struct NewNoteView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var relayService: RelayService
    @Environment(CurrentUser.self) var currentUser
    @EnvironmentObject private var router: Router
    @Dependency(\.analytics) private var analytics

    /// State holding the text the user is typing
    @State private var text = EditableNoteText()
    
    @State var expirationTime: TimeInterval?
    
    @State private var alert: AlertState<Never>?
    
    @State private var showRelayPicker = false
    @State private var selectedRelay: Relay?

    var initialContents: String?
    @Binding var isPresented: Bool

    init(initialContents: String? = nil, isPresented: Binding<Bool>) {
        _isPresented = isPresented
        self.initialContents = initialContents
    }
    
    @FocusState private var isTextEditorInFocus: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    NoteTextEditor(
                        text: $text, 
                        placeholder: .localizable.newNotePlaceholder,
                        focus: $isTextEditorInFocus
                    )
                    .padding(10)
                    Spacer()
                    ComposerActionBar(expirationTime: $expirationTime, text: $text)
                }
                
                if showRelayPicker, let author = currentUser.author {
                    RelayPicker(
                        selectedRelay: $selectedRelay,
                        defaultSelection: String(localized: .localizable.allMyRelays),
                        author: author,
                        isPresented: $showRelayPicker
                    )
                    .onChange(of: selectedRelay) { _, _ in
                        withAnimation {
                            showRelayPicker = false
                        }
                    }
                }
            }
            .background(Color.appBg)
            .navigationBarTitle(String(localized: .localizable.newNote), displayMode: .inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.cardBgBottom, for: .navigationBar)
            .toolbar {
                RelayPickerToolbarButton(
                    selectedRelay: $selectedRelay,
                    isPresenting: $showRelayPicker,
                    defaultSelection: .localizable.allMyRelays
                ) {
                    withAnimation {
                        showRelayPicker.toggle()
                    }
                }
            }
            .navigationBarItems(
                leading: Button {
                    isPresented = false
                }
                label: {
                    Text(.localizable.cancel)
                        .foregroundColor(.secondaryTxt)
                },
                trailing: ActionButton(title: .localizable.post, action: postAction)
                    .frame(height: 22)
                    .disabled(text.string.isEmpty)
                    .padding(.bottom, 3)
            )
            .onAppear {
                if let initialContents, text.isEmpty {
                    text = EditableNoteText(string: initialContents)
                }
                isTextEditorInFocus = true
                analytics.showedNewNote()
            }
        }
        .alert(unwrapping: $alert)
    }

    private func postAction() async {
        guard currentUser.keyPair != nil, let author = currentUser.author else {
            alert = AlertState(title: {
                TextState(String(localized: .localizable.error))
            }, message: {
                TextState(String(localized: .localizable.youNeedToEnterAPrivateKeyBeforePosting))
            })
            return
        }
        if let relay = selectedRelay {
            guard expirationTime == nil || relay.supportedNIPs?.contains(40) == true else {
                alert = AlertState(title: {
                    TextState(String(localized: .localizable.error))
                }, message: {
                    TextState(String(localized: .localizable.relayDoesNotSupportNIP40))
                })
                return
            }
        } else if expirationTime != nil {
            do {
                let relays = try await Relay.find(supporting: 40, for: author, context: viewContext)
                if relays.isEmpty {
                    alert = AlertState(title: {
                        TextState(String(localized: .localizable.error))
                    }, message: {
                        TextState(String(localized: .localizable.anyRelaysSupportingNIP40))
                    })
                    return
                }
            } catch {
                alert = AlertState(title: {
                    TextState(String(localized: .localizable.error))
                }, message: {
                    TextState(error.localizedDescription)
                })
                return
            }
        }
        Task {
            await publishPost()
        }
        isPresented = false
        router.selectedTab = .home
    }

    private func publishPost() async {
        guard let keyPair = currentUser.keyPair, let author = currentUser.author else {
            Log.error("Cannot post without a keypair")
            return
        }
        
        do {
            var (content, tags) = NoteParser.parse(attributedText: text.attributedString)
            
            if let expirationTime {
                tags.append(["expiration", String(Date.now.timeIntervalSince1970 + expirationTime)])
            }

            let jsonEvent = JSONEvent(pubKey: keyPair.publicKeyHex, kind: .text, tags: tags, content: content)
            
            if let relayURL = selectedRelay?.addressURL {
                try await relayService.publish(
                    event: jsonEvent,
                    to: relayURL,
                    signingKey: keyPair,
                    context: viewContext
                )
            } else if expirationTime != nil {
                let relays = try await Relay.find(supporting: 40, for: author, context: viewContext)
                try await relayService.publish(
                    event: jsonEvent, 
                    to: relays.compactMap { $0.addressURL }, 
                    signingKey: keyPair, 
                    context: viewContext
                )
            } else {
                try await relayService.publishToAll(event: jsonEvent, signingKey: keyPair, context: viewContext)
            }
            analytics.published(note: jsonEvent)
            text = EditableNoteText()
        } catch {
            Log.error("Error when posting: \(error.localizedDescription)")
        }
    }
}

struct NewPostView_Previews: PreviewProvider {
    
    static var previewData = PreviewData()
    static var persistenceController = PersistenceController.preview
    static var previewContext = persistenceController.container.viewContext
    static var relayService = previewData.relayService
    
    static var previews: some View {
        NewNoteView(isPresented: .constant(true))
            .environment(\.managedObjectContext, previewContext)
            .environmentObject(relayService)
    }
}
