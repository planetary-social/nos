import SwiftUI

struct ImagePickerUIViewController: UIViewControllerRepresentable {
    
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    var cameraDevice: UIImagePickerController.CameraDevice = .front
    var onCompletion: ((UIImage?) -> Void)

    func makeUIViewController(
        context: UIViewControllerRepresentableContext<ImagePickerUIViewController>
    ) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = sourceType
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
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: ImagePickerUIViewController
        init(_ parent: ImagePickerUIViewController) {
            self.parent = parent
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onCompletion(nil)
        }
        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let rect = (info[UIImagePickerController.InfoKey.cropRect] as? CGRect) ?? CGRect.zero
            let original = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
            let edited = info[UIImagePickerController.InfoKey.editedImage] as? UIImage
            let image = (rect.origin.x != 0 || rect.origin.y != 0) ? edited : original
            parent.onCompletion(image)
        }
    }
}
