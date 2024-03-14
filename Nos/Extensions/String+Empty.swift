import Foundation

extension Optional<String> {
    var isEmptyOrNil: Bool {
        self == nil || self?.isEmpty == true
    }
    
    var isNotEmptyAndNil: Bool {
        self?.isEmpty == false
    }
}
