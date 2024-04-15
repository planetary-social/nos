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
            } else {
                onCompletion(nil)
            }
        }
    }
}
