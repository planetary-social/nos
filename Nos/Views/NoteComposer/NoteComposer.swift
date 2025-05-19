import CoreData
import Dependencies
import Logger
import SwiftUI
import SwiftUINavigation
import Foundation

struct NoteComposer: View {

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(RelayService.self) private var relayService
    @Dependency(\.currentUser) private var currentUser
    @Dependency(\.analytics) private var analytics
    @Dependency(\.noteParser) private var noteParser
    @Dependency(\.persistenceController) private var persistenceController
    @Dependency(\.previewEventRepository) private var previewEventRepository

    /// A controller that manages the entered text.
    @State private var editingController = NoteEditorController()

    /// The height of the NoteTextEditor that fits all entered text.
    /// This value will be updated by NoteTextEditor automatically, and should be used to set its frame from SwiftUI.
    /// This is done to work around some incompatibilities between UIKit and SwiftUI where the UITextView won't expand
    /// properly.
    @State private var scrollViewHeight: CGFloat = 0

    @State private var expirationTime: TimeInterval?

    @State private var alert: AlertState<Never>?

    @State private var showRelayPicker = false
    @State private var selectedRelay: Relay?

    /// Shows a note preview above the composer.
    @State private var showNotePreview = false

    /// Event holding the preview note.
    @State private var previewEvent: Event?

    /// Whether we're currently uploading an image or not.
    @State private var isUploadingImage = false
    
    /// The kind of post being created
    @State private var postKind: PostKind = .textNote
    
    /// Title for media posts (Kind 20, 21, 22)
    @State private var mediaTitle: String = ""

    private let initialContents: String?
    @Binding var isPresented: Bool

    /// The note that the user is replying to, if any.
    private let replyToNote: Event?

    /// The id of a note the user is quoting, if any.
    private let quotedNoteID: RawEventID?

    /// The quoted note, if any.
    @State private var quotedNote: Event?

    /// The authors who are referenced in a note in addition to those who replied to the note, if any.
    private let relatedAuthors: [Author]

    init(
        initialContents: String? = nil,
        replyTo: Event? = nil,
        quotedNoteID: RawEventID? = nil,
        relatedAuthors: [Author] = [],
        isPresented: Binding<Bool>
    ) {
        _isPresented = isPresented
        self.initialContents = initialContents
        self.replyToNote = replyTo
        self.quotedNoteID = quotedNoteID
        self.relatedAuthors = relatedAuthors
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
            contentView
                .navigationTitle(navigationTitle)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .navigationBarItems(
                    leading: cancelButton,
                    trailing: postButton
                )
                .onAppear(perform: onAppearSetup)
                .task {
                    loadQuotedNote()
                }
        }
        .alert(unwrapping: $alert)
    }
    
    // Simple content view to reduce complexity
    private var contentView: some View {
        ZStack {
            // Main editor area
            VStack(spacing: 0) {
                mainEditorArea
                composerActionBar
            }
            .onChange(of: showNotePreview, perform: handlePreviewChange)
            
            // Overlays
            if isUploadingImage {
                uploadingIndicator
            }
            
            if let previewEvent = previewEvent {
                previewView(for: previewEvent)
            }
            
            if showRelayPicker, let author = currentUser.author {
                relayPickerView(author: author)
            }
        }
        .background(Color.gray.opacity(0.1))
    }
    
    // Editor area with simpler structure
    private var mainEditorArea: some View {
        GeometryReader { geometry in
            ScrollView {
                ScrollViewReader { proxy in
                    VStack(spacing: 0) {
                        // Reply preview if needed
                        if let replyToNote = replyToNote {
                            ReplyPreview(note: replyToNote)
                        }
                        
                        // Media title field if needed
                        if postKind != .textNote {
                            titleTextField
                        }
                        
                        // Note editor
                        editor
                        
                        // Quoted note if needed
                        if let quotedNote = quotedNote {
                            quotedNoteView(note: quotedNote)
                        }
                    }
                    .onAppear {
                        Task {
                            try? await Task.sleep(for: .seconds(0.5))
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
    }
    
    // Simple helper views
    private var titleTextField: some View {
        TextField("Title", text: $mediaTitle)
            .font(.clarity(.medium, textStyle: .title3))
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal, 10)
            .padding(.top, 10)
            .disabled(showNotePreview)
    }
    
    private var editor: some View {
        NoteTextEditor(
            controller: $editingController,
            minHeight: minimumEditorHeight,
            relatedAuthors: relatedAuthors
        )
        .padding(10)
        .disabled(showNotePreview)
        .background {
            Color.clear
                .frame(height: 1)
                .offset(y: 100)
                .id(0)
        }
    }
    
    private func quotedNoteView(note: Event) -> some View {
        NoteCard(
            note: note,
            hideOutOfNetwork: false,
            rendersQuotedNotes: false,
            showsActions: false
        )
        .withStyledBorder()
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    private var uploadingIndicator: some View {
        FullscreenProgressView(
            isPresented: .constant(true),
            text: String(localized: "uploading", table: "ImagePicker")
        )
    }
    
    private func previewView(for event: Event) -> some View {
        notePreview(for: event)
            .onDisappear {
                cleanupPreviewEvent(event)
            }
    }
    
    private func relayPickerView(author: Author) -> some View {
        RelayPicker(
            selectedRelay: $selectedRelay,
            defaultSelection: String(localized: "allMyRelays"),
            author: author,
            isPresented: $showRelayPicker
        )
        .onChange(of: selectedRelay) { _, _ in
            withAnimation {
                showRelayPicker = false
            }
        }
    }
    
    private var cancelButton: some View {
        Button(action: { isPresented = false }) {
            Text("cancel")
                .foregroundColor(.primary)
        }
    }
    
    private var postButton: some View {
        Button(action: { 
            Task { await postAction() }
        }) {
            Text("post")
                .foregroundColor(.primary)
                .bold()
        }
        .disabled(!isPostEnabled)
    }
    
    // MARK: - Helper Methods
    
    private func onAppearSetup() {
        if let initialContents, editingController.isEmpty {
            editingController.append(text: initialContents)
        }
        analytics.showedNoteComposer()
    }
    
    private func handlePreviewChange(_ newValue: Bool) {
        if newValue {
            createPreviewEvent()
        } else {
            withAnimation {
                self.previewEvent = nil
            }
        }
    }
    
    private func createPreviewEvent() {
        do {
            let jsonEvent = try jsonEvent(attributedString: postText)
            let event = try previewEventRepository.createPreviewEvent(
                from: jsonEvent,
                in: viewContext
            )
            if let event {
                withAnimation {
                    self.previewEvent = event
                }
            } else {
                Log.error("Couldn't create preview event")
                showNotePreview = false
            }
        } catch {
            Log.error("Error creating preview: \(error.localizedDescription)")
            showNotePreview = false
        }
    }
    
    private func cleanupPreviewEvent(_ event: Event) {
        do {
            try previewEventRepository.deletePreviewEvent(event, in: viewContext)
        } catch {
            Log.error("Couldn't delete preview event: \(error.localizedDescription)")
        }
    }

    /// Action Bar displayed below the editing controller.
    private var composerActionBar: some View {
        ComposerActionBar(
            editingController: $editingController,
            expirationTime: $expirationTime,
            isUploadingImage: $isUploadingImage,
            showPreview: $showNotePreview,
            postKind: $postKind
        )
    }

    /// Note Preview displayed above the editing controller when the Preview switch is turned on.
    private func notePreview(for note: Event) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                NoteButton(
                    note: note,
                    shouldTruncate: false,
                    hideOutOfNetwork: false,
                    repliesDisplayType: .displayNothing,
                    fetchReplies: false,
                    displayRootMessage: true,
                    isTapEnabled: false,
                    replyAction: nil,
                    tapAction: nil
                )
                .readabilityPadding()
                .padding(.vertical, 24)
            }
            composerActionBar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { Color.appBg }
        .transition(.opacity)
        .zIndex(1)
    }

    @MainActor private func postAction() async {
        // Validate user has a keypair
        guard let _ = currentUser.keyPair, let author = currentUser.author else {
            showErrorAlert(message: String(localized: "youNeedToEnterAPrivateKeyBeforePosting"))
            return
        }
        
        // Check if selected relay supports NIP-40 when using expiration time
        if let relay = selectedRelay {
            if !validateRelaySupportsExpiration(relay) {
                return
            }
        } else if expirationTime != nil {
            let relaysSupported = await validateAvailableRelaysForExpiration(author)
            if !relaysSupported {
                return
            }
        }
        
        // Publish the post and dismiss the composer
        Task {
            await publishPost()
        }
        isPresented = false
    }
    
    // MARK: - Post Validation Helpers
    
    private func showErrorAlert(message: String) {
        alert = AlertState(title: {
            TextState(String(localized: "error"))
        }, message: {
            TextState(message)
        })
    }
    
    private func validateRelaySupportsExpiration(_ relay: Relay) -> Bool {
        guard expirationTime == nil || relay.supportedNIPs?.contains(40) == true else {
            showErrorAlert(message: String(localized: "relayDoesNotSupportNIP40"))
            return false
        }
        return true
    }
    
    @MainActor
    private func validateAvailableRelaysForExpiration(_ author: Author) async -> Bool {
        do {
            let relays = try await Relay.find(supporting: 40, for: author, context: viewContext)
            if relays.isEmpty {
                showErrorAlert(message: String(localized: "anyRelaysSupportingNIP40"))
                return false
            }
            return true
        } catch {
            showErrorAlert(message: error.localizedDescription)
            return false
        }
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
        // For media posts, require a title
        if postKind != .textNote && mediaTitle.isEmpty {
            return false
        }
        return !isUploadingImage && (!editingController.isEmpty || quotedNote?.bech32NoteID.isEmptyOrNil == false)
    }
    
    /// Dynamic navigation title based on post kind
    private var navigationTitle: String {
        switch postKind {
        case .textNote:
            return String(localized: "newNote")
        case .picturePost:
            return String(localized: "newPicturePost")
        case .videoPost:
            return String(localized: "newVideoPost")
        case .shortVideo:
            return String(localized: "newShortVideo")
        }
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

    private func jsonEvent(attributedString: AttributedString) throws -> JSONEvent {
        guard let keyPair = currentUser.keyPair else {
            throw CurrentUserError.keyPairNotFound
        }
        
        // Extract media URLs from content
        let (content, tags) = noteParser.parse(attributedText: attributedString)
        let mediaURLs = extractMediaURLs(from: content)
        
        // Return the appropriate event type based on postKind
        switch postKind {
        case .textNote:
            return createTextNoteEvent(attributedString: attributedString, keyPair: keyPair)
        case .picturePost:
            return createPicturePostEvent(content: content, tags: tags, mediaURLs: mediaURLs, keyPair: keyPair)
        case .videoPost, .shortVideo:
            return createVideoPostEvent(content: content, tags: tags, mediaURLs: mediaURLs, keyPair: keyPair)
        }
    }
    
    // MARK: - Event Creation Helpers
    
    private func createTextNoteEvent(attributedString: AttributedString, keyPair: KeyPair) -> JSONEvent {
        // Standard text note
        return JSONEvent(
            attributedText: attributedString,
            noteParser: noteParser,
            expirationTime: expirationTime,
            replyToNote: replyToNote,
            keyPair: keyPair
        )
    }
    
    private func createPicturePostEvent(content: String, tags: [[String]], mediaURLs: [URL], keyPair: KeyPair) -> JSONEvent {
        // Picture post (Kind 20)
        let imageMetadata = createImageMetadata(from: mediaURLs)
        let finalTitle = mediaTitle.isEmpty ? "Untitled" : mediaTitle
        
        return JSONEvent.picturePost(
            pubKey: keyPair.publicKeyHex,
            title: finalTitle,
            description: content,
            imageMetadata: imageMetadata,
            tags: tags
        )
    }
    
    private func createVideoPostEvent(content: String, tags: [[String]], mediaURLs: [URL], keyPair: KeyPair) -> JSONEvent {
        // Video post (Kind 21/22)
        let videoMetadata = createVideoMetadata(from: mediaURLs)
        let finalTitle = mediaTitle.isEmpty ? "Untitled" : mediaTitle
        let isShortForm = postKind == .shortVideo
        
        return JSONEvent.videoPost(
            pubKey: keyPair.publicKeyHex,
            title: finalTitle,
            description: content,
            isShortForm: isShortForm,
            publishedAt: Int(Date.now.timeIntervalSince1970),
            duration: nil, // We don't have access to video duration
            videoMetadata: videoMetadata,
            contentWarning: nil,
            altText: nil,
            tags: tags
        )
    }
    
    /// Extracts media URLs from content text
    private func extractMediaURLs(from content: String) -> [URL] {
        let urlDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        guard let urlDetector = urlDetector else { return [] }
        
        let matches = urlDetector.matches(in: content, options: [], range: NSRange(location: 0, length: content.utf16.count))
        
        return matches.compactMap { match -> URL? in
            if let url = URL(string: (content as NSString).substring(with: match.range)) {
                // Check if it's likely a media URL (image or video)
                let pathExt = url.pathExtension.lowercased()
                let imageExts = ["jpg", "jpeg", "png", "gif", "webp"]
                let videoExts = ["mp4", "mov", "m4v", "webm", "mkv"]
                
                if imageExts.contains(pathExt) || videoExts.contains(pathExt) {
                    return url
                }
            }
            return nil
        }
    }
    
    /// Creates image metadata tags for NIP-68 picture posts
    private func createImageMetadata(from urls: [URL]) -> [[String]] {
        return urls.map { url -> [String] in
            let pathExt = url.pathExtension.lowercased()
            let mimeType: String
            
            switch pathExt {
            case "jpg", "jpeg":
                mimeType = "image/jpeg"
            case "png":
                mimeType = "image/png"
            case "gif":
                mimeType = "image/gif"
            case "webp":
                mimeType = "image/webp"
            default:
                mimeType = "image/\(pathExt)"
            }
            
            return ["imeta", "url \(url.absoluteString)", "m \(mimeType)"]
        }
    }
    
    /// Creates video metadata tags for NIP-71 video posts
    private func createVideoMetadata(from urls: [URL]) -> [[String]] {
        return urls.map { url -> [String] in
            let pathExt = url.pathExtension.lowercased()
            let mimeType: String
            
            switch pathExt {
            case "mp4":
                mimeType = "video/mp4"
            case "mov":
                mimeType = "video/quicktime"
            case "m4v":
                mimeType = "video/x-m4v"
            case "webm":
                mimeType = "video/webm"
            case "mkv":
                mimeType = "video/x-matroska"
            default:
                mimeType = "video/\(pathExt)"
            }
            
            return ["imeta", "url \(url.absoluteString)", "m \(mimeType)"]
        }
    }

    @MainActor private func publishPost() async {
        guard let keyPair = currentUser.keyPair, let author = currentUser.author else {
            Log.error("Cannot post without a keypair")
            return
        }
        guard isPostEnabled else {
            Log.error("Tried to publish a post with empty text")
            return
        }

        do {
            let jsonEvent = try jsonEvent(attributedString: postText)

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
