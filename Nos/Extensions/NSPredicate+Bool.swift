//
//  NSPredicate+Bool.swift
//  Nos
//
//  Created by Matthew Lorentz on 3/16/23.
//

import Foundation

extension NSPredicate {
    static var `false`: NSPredicate = {
        NSPredicate(format: "FALSEPREDICATE")
    }()
}
