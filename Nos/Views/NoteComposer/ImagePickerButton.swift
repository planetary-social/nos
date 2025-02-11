import AVKit
import SwiftUI
import Dependencies

struct ImagePickerButton<Label>: View where Label: View {

    /// The device to be used initially when the user chooses to use the camera.
    let cameraDevice: UIImagePickerController.CameraDevice
    /// The types of content the user can choose.
    let mediaTypes: [UTType]
    let onCompletion: ((URL) -> Void)
    let label: () -> Label

    /// State used to present or hide a confirmation dialog that lets the user select the ImagePicker source.
    @State
    private var showConfirmationDialog = false

    /// State used to present or hide an alert that lets the user go to settings.
    @State
    private var showSettingsAlert = false

    /// Source used by ImagePicker when opening it
    @State
    private var imagePickerSource: UIImagePickerController.SourceType?
    
    @Dependency(\.analytics) private var analytics
    
    @EnvironmentObject private var router: Router

    private var showImagePicker: Binding<Bool> {
        Binding {
            imagePickerSource != nil
        } set: { _ in
            imagePickerSource = nil
        }
    }

    private var settingsAlertTitle: String {
        let format = String(localized: "permissionsRequired", table: "ImagePicker")
        return String.localizedStringWithFormat(format, String(localized: "camera", table: "ImagePicker"))
    }

    var body: some View {
        Button {
            showConfirmationDialog = true
        } label: {
            label()
        }
        .confirmationDialog(
            "select",
            isPresented: $showConfirmationDialog,
            titleVisibility: .hidden
        ) {
            Button(cameraButtonTitle) {
                analytics.selectedUploadFromCamera()
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
                        showConfirmationDialog = false
                        return
                    }
                    imagePickerSource = .camera
                }
            }
            Button(String(localized: "selectFrom", table: "ImagePicker")) {
                analytics.selectedUploadFromPhotoLibrary()
                imagePickerSource = .photoLibrary
            }
            Button("cancel", role: .cancel) {
                analytics.cancelledUploadSourceSelection()
                showConfirmationDialog = false
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
                onCompletion: userPicked
            ) 
            .edgesIgnoringSafeArea(.bottom)
        }
    }
    
    private var cameraButtonTitle: String {
        String(
            localized: mediaTypes.contains(.movie) ? "takePhotoOrVideo" : "takePhoto",
            table: "ImagePicker"
        )
    }
    
    /// Called when a user chooses an image or video.
    /// - Parameter url: The URL of the image or video on disk.
    private func userPicked(url: URL?) {
        if let url {
            analytics.selectedImage()
            onCompletion(url)
        } else {
            analytics.cancelledImageSelection()
        }
        imagePickerSource = nil
    }
}

struct ImagePickerCoordinator_Previews: PreviewProvider {
    static var previews: some View {
        ImagePickerButton(cameraDevice: .rear, mediaTypes: [.image, .movie]) { pickedImage in
            print(pickedImage)
        } label: {
            Text("Hit me")
        }
    }
}
