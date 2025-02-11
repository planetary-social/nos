import SwiftUI

/// Displays our splash screen as a SwiftUI view
struct SplashScreenView: UIViewControllerRepresentable {

    private let storyboardName = "Launch Screen"

    // This function loads the storyboard and returns the view controller
    func makeUIViewController(context: Context) -> UIViewController {
        let storyboard = UIStoryboard(name: storyboardName, bundle: Bundle.main)
        let viewController = storyboard.instantiateInitialViewController() ?? UIViewController()
        return viewController
    }

    // Required but typically unused
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

#Preview {
    SplashScreenView()
}
