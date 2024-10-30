import SwiftUI
import AVKit
import Dependencies

struct HorizontalStreamCarousel: View {
    
    var streamName: String 
    
    var user: Author? 
    
    @FetchRequest var streamPhotos: FetchedResults<Event>
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var relayService: RelayService
    @Environment(CurrentUser.self) var currentUser
    @Dependency(\.fileStorageAPIClient) private var fileStorageAPIClient
    @State private var showPhotoMenu = false
    @State private var imagePickerSource: UIImagePickerController.SourceType?
    @State private var showSettingsAlert = false
    
    let cameraDevice: UIImagePickerController.CameraDevice = .rear
    let mediaTypes: [UTType] = [.image]
    
    init(streamName: String, showComposeButtonFor user: Author? = nil) {
        self.streamName = streamName
        self.user = user
        _streamPhotos = FetchRequest(fetchRequest: Event.by(hashtag: streamName))
    }
    
    private var showImagePicker: Binding<Bool> {
        Binding {
            imagePickerSource != nil
        } set: { _ in
            imagePickerSource = nil
        }
    }
    
    private var cameraButtonTitle: String {
        String(
            localized: mediaTypes.contains(.movie) ? "takePhotoOrVideo" : "takePhoto",
            table: "ImagePicker"
        )
    }
    
    private var settingsAlertTitle: String {
        let format = String(localized: "permissionsRequired", table: "ImagePicker")
        return String.localizedStringWithFormat(format, String(localized: "camera", table: "ImagePicker"))
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(streamName)
                    .font(.title)
                Spacer()
            }
            .padding(.top)
            
            if let authorName = streamPhotos.last?.author?.safeName {
                HStack {
                    Text("by ") + Text(authorName).underline()
                    Spacer()
                }
                .font(.callout)
            }
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    if let user {
                        Button { 
                            addPhotoPressed()
                        } label: { 
                            ZStack {
                                Rectangle()
                                    .foregroundStyle(LinearGradient.verticalAccentSecondary)
                                    .cornerRadius(5)
                                    .padding(30)
                                Image(systemName: "plus")
                                    .foregroundStyle(Color.white)
                                    .font(.system(size: 40)) 
                            }
                            .frame(width: 140, height: 140)
                        }
                    }
                    ForEach(streamPhotos) { photoEvent in
                        VStack {
                            if !photoEvent.contentLinks.isEmpty {
                                GalleryView(
                                    urls: Array(photoEvent.contentLinks.prefix(1)),
                                    metadata: photoEvent.inlineMetadata
                                )
                                .cornerRadius(3)
                            }
                        }
                        .task { await photoEvent.loadAttributedContent() }
                    }
                }
                .frame(height: 200)
            }
        }
        .padding()
        .confirmationDialog(
            "select",
            isPresented: $showPhotoMenu,
            titleVisibility: .hidden
        ) {
            Button(cameraButtonTitle) {
                // Check permissions
                
                // simulator
                guard !UIDevice.isSimulator else {
                    imagePickerSource = .camera
                    return
                }
                
                // denied
                let status = AVCaptureDevice.authorizationStatus(for: .video)
                guard status != .denied, status != .restricted else {
                    showSettingsAlert = true
                    return
                }
                
                // allowed
                if status == .authorized {
                    imagePickerSource = .camera
                    return
                }
                
                // unknown
                AVCaptureDevice.requestAccess(for: .video) { allowed in
                    guard allowed else {
                        showPhotoMenu = false
                        return
                    }
                    imagePickerSource = .camera
                }
            }
            Button(String(localized: "selectFrom", table: "ImagePicker")) {
                imagePickerSource = .photoLibrary
            }
            Button("cancel", role: .cancel) {
                showPhotoMenu = false
            }
        }
        .alert(
            settingsAlertTitle,
            isPresented: $showSettingsAlert,
            actions: {
                Button("settings") {
                    showSettingsAlert = false
                    self.router.openOSSettings()
                }
                Button("cancel") {
                    showSettingsAlert = false
                }
            },
            message: {
                Text("openSettingsMessage", tableName: "ImagePicker")
            }
        )
        .sheet(isPresented: showImagePicker) {
            ImagePickerUIViewController(
                sourceType: imagePickerSource ?? .photoLibrary, 
                mediaTypes: mediaTypes,
                cameraDevice: cameraDevice,
                onCompletion: addPhoto
            ) 
            .edgesIgnoringSafeArea(.bottom)
        }
    }
    
    func addPhotoPressed() {
        showPhotoMenu = true 
    }
    
    func addPhoto(photoURL: URL?) {
        imagePickerSource = nil
        Task {
            guard let photoURL else {
                return
            }
            let url = try await fileStorageAPIClient.upload(fileAt: photoURL, isProfilePhoto: false)
            
            let content = url.absoluteString
            
            guard let keyPair = currentUser.keyPair else {
                throw CurrentUserError.keyPairNotFound
            }
            let jsonEvent = JSONEvent(
                pubKey: currentUser.keyPair!.publicKeyHex,
                kind: .text,
                tags: [["t", streamName]],
                content: content
            )
            try await relayService.publishToAll(event: jsonEvent, signingKey: keyPair, context: viewContext)
        }
    }
}

#Preview {
    var previewData = PreviewData()
    
    func createTestData() {
        let user = previewData.alice
        let addresses = Relay.recommended
        addresses.forEach { address in
            let relay = try? Relay.findOrCreate(by: address, context: previewData.previewContext)
            relay?.relayDescription = "A Nostr relay that aims to cultivate a healthy community."
            relay?.addToAuthors(user)
        }
        
        Task { try await previewData.currentUser.follow(author: previewData.bob) }
        
        _ = previewData.streamImageOne
        _ = previewData.streamImageTwo
        _ = previewData.streamImageThree
    }
    
    return HorizontalStreamCarousel(streamName: "🇺🇾 Uruguay", showComposeButtonFor: previewData.previewAuthor)
        .inject(previewData: previewData)
        .onAppear { createTestData() }
}
