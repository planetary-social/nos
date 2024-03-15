import Foundation

extension Optional {
    @discardableResult
    func unwrap<T>(_ then: (Wrapped) -> T?) -> T? {
        switch self {
        case .none:
            return nil
        case .some(let unwrapped):
            return then(unwrapped)
        }
    }
}
