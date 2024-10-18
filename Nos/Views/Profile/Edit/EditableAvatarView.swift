import Dependencies
import SwiftUI
import SwiftUINavigation

/// An avatar view that allows the user to tap and select from the photo library or
/// take a photo with the camera.
struct EditableAvatarView: View {
    let size: CGFloat
    
    /// The remote URL string of the selected photo after upload.
    @Binding var urlString: String
    
    /// If true, the selected photo is currently being uploaded.
    @Binding var isUploadingPhoto: Bool
    
    @Dependency(\.fileStorageAPIClient) private var fileStorageAPIClient
    
    @State private var selectedPhoto: Image?
    @State private var alert: AlertState<AlertAction>?
    fileprivate enum AlertAction {}
    
    var body: some View {
        ImagePickerButton(cameraDevice: .front, mediaTypes: [.image]) { imageURL in
            Task { await uploadItem(at: imageURL) }
        } label: {
            ZStack {
                if let selectedPhoto {
                    selectedPhoto
                        .resizable()
                        .renderingMode(.original)
                        .aspectRatio(1, contentMode: .fill)
                        .clipShape(Circle())
                } else {
                    AvatarView(imageUrl: URL(string: urlString), size: size)
                }
                
                HStack {
                    Spacer()
                    
                    VStack {
                        Spacer()
                        
                        Image.editButton
                            .offset(x: 4, y: 6)
                    }
                }
                
                if isUploadingPhoto {
                    ProgressView()
                        .scaleEffect(1.5)
                }
            }
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        }
        .frame(width: size, height: size)
        .disabled(isUploadingPhoto)
        .alert(unwrapping: $alert) { _ in }
    }
    
    /// Uploads the photo the user selected and, on success, fills the avatar url field.
    /// - Parameter fileURL: A URL that points to a file to upload.
    private func uploadItem(at fileURL: URL) async {
        assert(fileURL.isFileURL, "The URL must point to a file.")
        
        isUploadingPhoto = true
        defer {
            isUploadingPhoto = false
        }
        
        // show the image to the user while uploading
        if let data = try? Data(contentsOf: fileURL),
            let image = UIImage(data: data) {
            selectedPhoto = Image(uiImage: image)
        }
        
        do {
            let url = try await fileStorageAPIClient.upload(fileAt: fileURL, isProfilePhoto: true)
            urlString = url.absoluteString
        } catch {
            alert = AlertState(title: {
                TextState(String(localized: "errorUploadingFile", table: "ImagePicker"))
            }, message: {
                if case let FileStorageAPIClientError.uploadFailed(message) = error,
                    let message {
                    TextState(
                        String.localizedStringWithFormat(
                            String(localized: "errorUploadingFileWithMessage", table: "ImagePicker"), message
                        )
                    )
                } else {
                    TextState(String(localized: "errorUploadingFileMessage", table: "ImagePicker"))
                }
            })
        }
    }
}

#Preview {
    EditableAvatarView(
        size: 99,
        urlString: .constant("test"),
        isUploadingPhoto: .constant(false)
    )
}
