import Foundation
import UIKit

extension UIDevice {

    static var isSimulator: Bool {
        ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != nil
    }
}
