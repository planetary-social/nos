import UIKit
import SwiftUI

struct ActivityViewController: UIViewControllerRepresentable {

    var activityItems: [Any]
    var applicationActivities: [UIActivity]?
    var completion: (() -> Void)? // Completion handler for dismissing the sheet

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
