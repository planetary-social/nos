import Foundation

extension String? {
    var isEmptyOrNil: Bool {
        self == nil || self?.isEmpty == true
    }
}
