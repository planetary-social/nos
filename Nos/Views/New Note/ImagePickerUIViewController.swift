import Logger
import SwiftUI
import UniformTypeIdentifiers

struct ImagePickerUIViewController: UIViewControllerRepresentable {
    
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    var cameraDevice: UIImagePickerController.CameraDevice = .front
    var onCompletion: ((URL?) -> Void)

    func makeUIViewController(
        context: UIViewControllerRepresentableContext<ImagePickerUIViewController>
    ) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = sourceType
        imagePicker.mediaTypes = [UTType.image.identifier, UTType.movie.identifier]
        imagePicker.delegate = context.coordinator
        if sourceType == .camera {
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
            if let videoURL = info[.mediaURL] as? URL {
                onCompletion(videoURL)
            } else if let imageURL = info[.imageURL] as? URL {
                onCompletion(imageURL)
            } else if let image = info[.originalImage] as? UIImage,
                let imageData = image.jpegData(compressionQuality: 1.0) {
                let url = saveImage(imageData)
                onCompletion(url)
            } else {
                onCompletion(nil)
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
