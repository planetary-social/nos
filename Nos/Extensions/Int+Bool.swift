import Foundation

extension Int32 {
    var boolValue: Bool {
        Bool(truncating: NSNumber(value: self))
    }
}
