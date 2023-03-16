//
//  Optional+Unwrap.swift
//  Nos
//
//  Created by Matthew Lorentz on 3/16/23.
//

import Foundation

extension Optional {
    func unwrap(_ then: (Wrapped) -> Void) {
        switch self {
        case .none:
            return
        case .some(let unwrapped):
            then(unwrapped)
        }
    }
}
