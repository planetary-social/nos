import AVKit
import SwiftUI
import Dependencies

struct ImagePickerButton<Label>: View where Label: View {

    var onCompletion: ((UIImage) -> Void)

    var label: () -> Label

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
    
    @Environment(Router.self) private var router

    private var showImagePicker: Binding<Bool> {
        Binding {
            imagePickerSource != nil
        } set: { _ in
            imagePickerSource = nil
        }
    }

    private var settingsAlertTitle: String {
        Localized.ImagePicker.permissionsRequired.text(["title": Localized.ImagePicker.camera.string])
    }

    var body: some View {
        Button {
            showConfirmationDialog = true
        } label: {
            label()
        }
        .confirmationDialog(Localized.select.string, isPresented: $showConfirmationDialog, titleVisibility: .hidden) {
            Button(Localized.ImagePicker.takePhoto.string) {
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
            Button(Localized.ImagePicker.selectFrom.string) {
                analytics.selectedUploadFromPhotoLibrary()
                imagePickerSource = .photoLibrary
            }
            Button(Localized.cancel.string, role: .cancel) {
                analytics.cancelledUploadSourceSelection()
                showConfirmationDialog = false
            }
        }
        .alert(
            settingsAlertTitle,
            isPresented: $showSettingsAlert,
            actions: {
                Button(Localized.settings.string) {
                    showSettingsAlert = false
                    self.router.openOSSettings()
                }
                Button(Localized.cancel.string) {
                    showSettingsAlert = false
                }
            },
            message: {
                Text(Localized.ImagePicker.openSettingsMessage.string)
            }
        )
        .sheet(isPresented: showImagePicker) {
            ImagePicker(sourceType: imagePickerSource ?? .photoLibrary, cameraDevice: .rear) { imagePicked in
                if let image = imagePicked {
                    analytics.selectedImage()
                    onCompletion(image)
                } else {
                    analytics.cancelledImageSelection()
                }
                imagePickerSource = nil
            }
        }
    }
}

struct ImagePickerCoordinator_Previews: PreviewProvider {
    @State
    static var isPresented = true

    static var previews: some View {
        ImagePickerButton { pickedImage in
            print(pickedImage)
        } label: {
            Text("Hit me")
        }
    }
}
