//
//  Int+Bool.swift
//  Nos
//
//  Created by Matthew Lorentz on 2/21/23.
//

import Foundation

// swiftlint:disable legacy_objc_type
extension Int32 {
    var boolValue: Bool {
        Bool(truncating: NSNumber(value: self))
    }
}
