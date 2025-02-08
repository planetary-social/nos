import UIKit
import SwiftUI

struct ActivityViewController: UIViewControllerRepresentable {

    let activityItems: [Any]
    var applicationActivities: [UIActivity]?
    /// The completion handler to execute after the activity view controller is dismissed.
    var completion: (() -> Void)?

    func makeUIViewController(
        context: UIViewControllerRepresentableContext<ActivityViewController>
    ) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        controller.completionWithItemsHandler = { _, _, _, _  in
            completion?()
        }
        return controller
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: UIViewControllerRepresentableContext<ActivityViewController>
    ) { }
}
