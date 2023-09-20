//
//  Optional+Unwrap.swift
//  Nos
//
//  Created by Matthew Lorentz on 3/16/23.
//

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
