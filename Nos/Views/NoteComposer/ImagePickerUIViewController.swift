import Logger
import SwiftUI
import UniformTypeIdentifiers

struct ImagePickerUIViewController: UIViewControllerRepresentable {
    
    let sourceType: UIImagePickerController.SourceType
    let mediaTypes: [UTType]
    let cameraDevice: UIImagePickerController.CameraDevice
    let onCompletion: (URL?) -> Void
    
    init(
        sourceType: UIImagePickerController.SourceType = .photoLibrary,
        mediaTypes: [UTType] = [.image, .movie],
        cameraDevice: UIImagePickerController.CameraDevice = .front,
        onCompletion: @escaping (URL?) -> Void
    ) {
        assert(!mediaTypes.isEmpty, "Must provide at least one media type")
        self.sourceType = sourceType
        self.mediaTypes = mediaTypes
        self.cameraDevice = cameraDevice
        self.onCompletion = onCompletion
    }
    
    func makeUIViewController(
        context: UIViewControllerRepresentableContext<ImagePickerUIViewController>
    ) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            imagePicker.sourceType = sourceType
        }
        imagePicker.mediaTypes = mediaTypes.map { $0.identifier }
        imagePicker.delegate = context.coordinator
        if sourceType == .camera && UIImagePickerController.isCameraDeviceAvailable(cameraDevice) {
            imagePicker.cameraDevice = cameraDevice
        }
        return imagePicker
    }

    func updateUIViewController(
        _ uiViewController: UIImagePickerController,
        context: UIViewControllerRepresentableContext<ImagePickerUIViewController>
    ) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(onCompletion: onCompletion)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var onCompletion: ((URL?) -> Void)

        init(onCompletion: @escaping ((URL?) -> Void)) {
            self.onCompletion = onCompletion
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCompletion(nil)
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            DispatchQueue.main.async {
                if let videoURL = info[.mediaURL] as? URL {
                    self.onCompletion(videoURL)
                } else if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage,
                    let imageData = image.jpegData(compressionQuality: 1.0) {
                    let url = self.saveImage(imageData)
                    self.onCompletion(url)
                } else if let imageURL = info[.imageURL] as? URL {
                    self.onCompletion(imageURL)
                } else {
                    self.onCompletion(nil)
                }
            }
        }

        /// Saves the given image data to a JPG file and returns the URL of the file.
        /// - Parameter imageData: The image data to save to disk.
        /// - Returns: The URL of the image file.
        private func saveImage(_ imageData: Data) -> URL? {
            let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let documentDirectory = urls[0]
            let fileURL = documentDirectory.appendingPathComponent("capturedImage.jpg")

            do {
                try imageData.write(to: fileURL, options: .atomic)
                return fileURL
            } catch {
                Log.debug("Error saving image: \(error)")
                return nil
            }
        }
    }
}
