import CoreData
import Dependencies
import Logger
import SwiftUI
import SwiftUINavigation

struct NoteComposer: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var relayService: RelayService
    @Environment(CurrentUser.self) var currentUser
    @Dependency(\.analytics) private var analytics
    @Dependency(\.noteParser) private var noteParser
    @Dependency(\.persistenceController) private var persistenceController

    /// A controller that manages the entered text.
    @State private var editingController = NoteEditorController()

    /// The height of the NoteTextEditor that fits all entered text.
    /// This value will be updated by NoteTextEditor automatically, and should be used to set its frame from SwiftUI. 
    /// This is done to work around some incompatibilities between UIKit and SwiftUI where the UITextView won't expand 
    /// properly.
    @State private var scrollViewHeight: CGFloat = 0

    @State var expirationTime: TimeInterval?
    
    @State private var alert: AlertState<Never>?
    
    @State private var showRelayPicker = false
    @State private var selectedRelay: Relay?
    
    /// Shows a note preview above the composer.
    @State private var showNotePreview = false

    /// Event holding the preview note.
    @State private var previewEvent: Event?

    /// Whether we're currently uploading an image or not.
    @State private var isUploadingImage = false

    var initialContents: String?
    @Binding var isPresented: Bool
    
    /// The note that the user is replying to, if any.
    private var replyToNote: Event?
    
    /// The id of a note the user is quoting, if any.
    private let quotedNoteID: RawEventID?
    
    /// The quoted note, if any.
    @State private var quotedNote: Event?

    init(
        initialContents: String? = nil,
        replyTo: Event? = nil,
        quotedNoteID: RawEventID? = nil,
        isPresented: Binding<Bool>
    ) {
        _isPresented = isPresented
        self.initialContents = initialContents
        self.replyToNote = replyTo
        self.quotedNoteID = quotedNoteID
    }
    
    /// The minimum height of the NoteTextEditor.
    /// 
    /// We do this because editor won't expand to fill available space when it's in a ScrollView.
    /// And we need it to because people try to tap below the text field bounds to paste if it doesn't
    /// fill the screen. We remove this minimum in the case that a user is quote-reposting another note.
    var minimumEditorHeight: CGFloat {
        quotedNote == nil ? max(scrollViewHeight - 12, 0) : 0
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
                                        controller: $editingController,
                                        minHeight: minimumEditorHeight,
                                        placeholder: .localizable.newNotePlaceholder
                                    )
                                    .padding(10)
                                    .disabled(showNotePreview)
                                    .background {
                                        // This is a placeholder view that lets us scroll the editor just into view.
                                        Color.clear
                                            .frame(height: 1)
                                            .offset(y: 100)
                                            .id(0)
                                    }
                                    if let quotedNote {
                                        NoteCard(
                                            note: quotedNote,
                                            hideOutOfNetwork: false,
                                            rendersQuotedNotes: false,
                                            showsActions: false
                                        )
                                        .withStyledBorder()
                                        .padding(.horizontal, 16)
                                        .padding(.bottom, 16)
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
                    
                    composerActionBar
                }
                
                if isUploadingImage {
                    FullscreenProgressView(
                        isPresented: .constant(true),
                        text: String(localized: .imagePicker.uploading)
                    )
                }

                if showNotePreview {
                    notePreview
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
                    .disabled(!isPostEnabled)
                    .padding(.bottom, 3)
            )
            .onAppear {
                if let initialContents, editingController.isEmpty {
                    editingController.append(text: initialContents)
                }
                analytics.showedNoteComposer()
            }
            .task {
                loadQuotedNote()
            }
        }
        .alert(unwrapping: $alert)
    }

    /// Action Bar displayed below the editing controller.
    private var composerActionBar: some View {
        ComposerActionBar(
            editingController: $editingController,
            expirationTime: $expirationTime,
            isUploadingImage: $isUploadingImage,
            showPreview: $showNotePreview
        )
    }

    /// Note Preview displayed above the editing controller when the Preview switch is turned on.
    private var notePreview: some View {
        VStack(spacing: 0) {
            Group {
                if let previewEvent {
                    ScrollView {
                        NoteButton(
                            note: previewEvent,
                            shouldTruncate: false,
                            hideOutOfNetwork: false,
                            repliesDisplayType: .displayNothing,
                            fetchReplies: false,
                            displayRootMessage: true,
                            isTapEnabled: false,
                            replyAction: nil,
                            tapAction: nil
                        )
                        .id(previewEvent)
                        .readabilityPadding()
                        .padding(.vertical, 24)
                        .allowsHitTesting(false)
                        .onDisappear {
                            do {
                                try deletePreviewEvent(previewEvent)
                            } catch {
                                Log.error("Couldn't delete preview event: \(error.localizedDescription)")
                            }
                        }
                    }
                } else {
                    ProgressView()
                        .onAppear {
                            let text = editingController.text ?? AttributedString()
                            do {
                                try createPreviewEvent(from: text)
                            } catch {
                                Log.error("Error creating preview: \(error.localizedDescription)")
                            }
                        }
                }
            }
            composerActionBar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { Color.appBg }
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
    
    private func loadQuotedNote() {
        guard let quotedNoteID else {
            return
        }
        
        quotedNote = try? Event.findOrCreateStubBy(
            id: quotedNoteID,
            context: persistenceController.viewContext
        )
    }

    private var isPostEnabled: Bool {
        !isUploadingImage && (!editingController.isEmpty || quotedNote?.bech32NoteID.isEmptyOrNil == false)
    }
    
    private var postText: AttributedString {
        var text = editingController.text ?? ""
        if let noteLink = quotedNote?.bech32NoteID {
            if !text.characters.isEmpty {
                text += AttributedString("\n\n")
            }
            text += AttributedString("nostr:\(noteLink)")
        }
        return text
    }

    private func publishPost() async {
        guard let keyPair = currentUser.keyPair, let author = currentUser.author else {
            Log.error("Cannot post without a keypair")
            return
        }
        guard isPostEnabled else {
            Log.error("Tried to publish a post with empty text")
            return
        }
        
        let text = postText
        
        do {
            let jsonEvent = buildJSONEvent(attributedText: text, keyPair: keyPair)

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
            if replyToNote != nil {
                analytics.published(reply: jsonEvent)
            } else {
                analytics.published(note: jsonEvent)
            }
        } catch {
            Log.error("Error when posting: \(error.localizedDescription)")
        }
    }

    /// Builds a JSONEvent object for a given text and key pair.
    /// - Parameters:
    ///   - attributedText: The text the user wrote.
    ///   - keyPair: Key pair of the logged in user.
    /// - Returns: A JSONEvent object suitable to be published to Nostr.
    private func buildJSONEvent(attributedText: AttributedString, keyPair: KeyPair) -> JSONEvent {
        var (content, tags) = noteParser.parse(attributedText: attributedText)

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

        return JSONEvent(pubKey: keyPair.publicKeyHex, kind: .text, tags: tags, content: content)
    }

    /// Creates a preview event object from what the user wrote in the editing controller.
    /// - Parameter attributedText: Text being previewed.
    private func createPreviewEvent(from attributedText: AttributedString) throws {
        guard let keyPair = currentUser.keyPair else {
            Log.error("Cannot create a preview event without a keypair")
            throw CurrentUserError.keyPairNotFound
        }
        if let oldPreviewEvent = Event.find(by: Event.previewIdentifier, context: viewContext) {
            try deletePreviewEvent(oldPreviewEvent)
        }
        var jsonEvent = buildJSONEvent(
            attributedText: attributedText,
            keyPair: keyPair
        )
        jsonEvent.id = Event.previewIdentifier
        previewEvent = try EventProcessor.parse(
            jsonEvent: jsonEvent,
            from: nil,
            in: viewContext,
            skipVerification: true
        )
    }

    /// Deletes the preview event object from the database.
    /// - Parameter event: Event to delete from the database.
    private func deletePreviewEvent(_ event: Event) throws {
        viewContext.delete(event)
        try viewContext.saveIfNeeded()
        previewEvent = nil
    }
}

#Preview {
    let previewData = PreviewData()

    return NoteComposer(isPresented: .constant(true))
        .inject(previewData: previewData)
}

#Preview {
    var previewData = PreviewData()

    return NoteComposer(replyTo: previewData.longNote, isPresented: .constant(true))
        .inject(previewData: previewData)
}
