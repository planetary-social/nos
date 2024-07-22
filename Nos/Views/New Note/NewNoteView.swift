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
    @Dependency(\.noteParser) private var noteParser

    /// State holding the text the user is typing
    @State private var text = EditableNoteText()

    /// The height of the NoteTextEditor that fits all entered text.
    /// This value will be updated by NoteTextEditor automatically, and should be used to set its frame from SwiftUI. 
    /// This is done to work around some incompatibilities between UIKit and SwiftUI where the UITextView won't expand 
    /// properly.
    @State private var scrollViewHeight: CGFloat = 0

    @State var expirationTime: TimeInterval?
    
    @State private var alert: AlertState<Never>?
    
    @State private var showRelayPicker = false
    @State private var selectedRelay: Relay?

    /// Whether we're currently uploading an image or not.
    @State private var isUploadingImage = false

    var initialContents: String?
    @Binding var isPresented: Bool
    
    /// The note that the user is replying to, if any.
    private var replyToNote: Event?

    init(initialContents: String? = nil, replyTo: Event? = nil, isPresented: Binding<Bool>) {
        _isPresented = isPresented
        self.initialContents = initialContents
        self.replyToNote = replyTo
    }
    
    /// The minimum height of the NoteTextEditor.
    /// 
    /// We do this because editor won't expand to fill available space when it's in a ScrollView.
    /// and we need it to because people try to tap below the text field bounds to paste if it doesn't
    /// fill the screen.
    var minimumEditorHeight: CGFloat {
        max(scrollViewHeight - 12, 0)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    GeometryReader { geometry in
                        ScrollView {
                            ScrollViewReader { proxy in
                                VStack(spacing: 0) {
                                    if let replyToNote {
                                        ReplyPreview(note: replyToNote)
                                    }
                                    NoteTextEditor(
                                        text: $text, 
                                        minHeight: minimumEditorHeight,
                                        placeholder: .localizable.newNotePlaceholder
                                    )
                                    .padding(10)
                                    .background {
                                        // This is a placeholder view that lets us scroll the editor just into view.
                                        Color.clear
                                            .frame(height: 1)
                                            .offset(y: 100)
                                            .id(0)
                                    }
                                }
                                .onAppear {
                                    Task {
                                        try await Task.sleep(for: .seconds(0.5))
                                        withAnimation(.easeInOut(duration: 0.25)) { 
                                            proxy.scrollTo(0, anchor: nil)
                                        }
                                    }
                                }
                            }
                        }
                        .onChange(of: geometry.size.height) { _, newValue in
                            scrollViewHeight = newValue 
                        }
                    }
                    
                    ComposerActionBar(
                        expirationTime: $expirationTime,
                        isUploadingImage: $isUploadingImage,
                        text: $text
                    )
                }
                
                if isUploadingImage {
                    FullscreenProgressView(
                        isPresented: .constant(true),
                        text: String(localized: .imagePicker.uploading)
                    )
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
                        .foregroundColor(.primaryTxt)
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
    }

    private func publishPost() async {
        guard let keyPair = currentUser.keyPair, let author = currentUser.author else {
            Log.error("Cannot post without a keypair")
            return
        }
        
        do {
            var (content, tags) = noteParser.parse(attributedText: text.attributedString)
            
            if let expirationTime {
                tags.append(["expiration", String(Date.now.timeIntervalSince1970 + expirationTime)])
            }
            
            // Attach the new note to the one it is replying to, if any.
            if let replyToNote = replyToNote, let replyToNoteID = replyToNote.identifier {
                // TODO: Append ptags for all authors involved in the thread
                if let replyToAuthor = replyToNote.author?.publicKey?.hex {
                    tags.append(["p", replyToAuthor])
                }
                
                // If `note` is a reply to another root, tag that root
                if let rootNoteIdentifier = replyToNote.rootNote()?.identifier, rootNoteIdentifier != replyToNoteID {
                    tags.append(["e", rootNoteIdentifier, "", EventReferenceMarker.root.rawValue])
                    tags.append(["e", replyToNoteID, "", EventReferenceMarker.reply.rawValue])
                } else {
                    tags.append(["e", replyToNoteID, "", EventReferenceMarker.root.rawValue])
                }
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
            if let replyToNote {
                analytics.published(reply: jsonEvent)
            } else {
                analytics.published(note: jsonEvent)
            }
            text = EditableNoteText()
        } catch {
            Log.error("Error when posting: \(error.localizedDescription)")
        }
    }
}

#Preview {
    let previewData = PreviewData()
    
    return NewNoteView(isPresented: .constant(true))
        .inject(previewData: previewData)
}

#Preview {
    var previewData = PreviewData()
    
    return NewNoteView(replyTo: previewData.longNote, isPresented: .constant(true))
        .inject(previewData: previewData)
}
