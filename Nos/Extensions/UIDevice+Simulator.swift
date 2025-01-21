import Foundation
import UIKit

extension UIDevice {

    static var isSimulator: Bool {
        ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != nil
    }

    static var platformName: String {
    #if os(iOS)
        return UIDevice.current.systemName
    #elseif os(macOS)
        return "macOS"
    #endif
    }
}
