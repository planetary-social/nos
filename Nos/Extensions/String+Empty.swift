//
//  String+Empty.swift
//  Nos
//
//  Created by Matthew Lorentz on 10/27/23.
//

import Foundation

extension Optional<String> {
    var isEmptyOrNil: Bool {
        self == nil || self?.isEmpty == true
    }
    
    var isNotEmptyAndNil: Bool {
        self?.isEmpty == false
    }
}
