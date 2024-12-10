import SwiftUI
import UIKit

struct TabBarController: UIViewControllerRepresentable {
    @Binding var selectedIndex: AppDestination
    let viewControllers: [UIViewController]
    
    func makeUIViewController(context: Context) -> UITabBarController {
        let tabController = WorkaroundTabBarController()
        tabController.viewControllers = viewControllers
        tabController.delegate = context.coordinator

        tabController.tabBar.backgroundColor = .cardBgBottom
        tabController.tabBar.isTranslucent = true
        tabController.tabBar.tintColor = .primaryTxt
        tabController.tabBar.unselectedItemTintColor = .secondaryTxt

        // removes the translucency to match the design
        tabController.tabBar.backgroundImage = UIImage()
        tabController.tabBar.shadowImage = UIImage()

        return tabController
    }
    
    func updateUIViewController(_ tabController: UITabBarController, context: Context) {
        if case .noteComposer = selectedIndex {
            // Don't update tab selection for composer
            return
        }
        tabController.selectedIndex = selectedIndex.tabIndex
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITabBarControllerDelegate {
        var parent: TabBarController
        
        init(_ parent: TabBarController) {
            self.parent = parent
        }
        
        func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
            parent.selectedIndex = AppDestination.tabDestinations[tabBarController.selectedIndex]
        }
    }
}

class WorkaroundTabBarController: UITabBarController {
    init() {
        super.init(nibName: nil, bundle: nil)

        // Fix for macOS Sequoia: without this, the tabs appear twice and the view crashes regularly.
        if #available(iOS 18, *), ProcessInfo.processInfo.isiOSAppOnMac {
            // Hides the top tabs
            mode = .tabSidebar
            sidebar.isHidden = true
            traitOverrides.horizontalSizeClass = .compact
            additionalSafeAreaInsets.bottom = 10
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
