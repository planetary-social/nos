import Foundation

extension NSPredicate {
    static var `false`: NSPredicate = {
        NSPredicate(format: "FALSEPREDICATE")
    }()
}
