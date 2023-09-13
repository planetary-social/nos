//
//  Text+Localized.swift
//  Nos
//
//  Created by Matthew Lorentz on 9/13/23.
//

import Foundation
import SwiftUI

extension Text {
    init(_ localizable: Localized) {
        self.init(localizable.string)
    }
}
