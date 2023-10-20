//
//  ReadabilityPadding.swift
//  Nos
//
//  Created by Matthew Lorentz on 4/20/23.
//

import Foundation
import SwiftUI

extension View {
    func readabilityPadding(isEnabled: Bool = true) -> some View {
        self.modifier(ReadabilityPadding(isEnabled: isEnabled))
    }
    
    func getReadabilityPadding(isEnabled: Bool = true) -> ReadabilityPadding {
        ReadabilityPadding(isEnabled: isEnabled)
    }
    
    func reducedWidthPadding(reduction: CGFloat) -> some View {
        self.modifier(ReducedWidthPadding(reduction: reduction, baseModifier: getReadabilityPadding(isEnabled: true)))
    }
}

// Based on https://stackoverflow.com/a/68478487/982195
struct ReadabilityPadding: ViewModifier {
    let isEnabled: Bool
    @ScaledMetric private var unit: CGFloat = 20
    
    func body(content: Content) -> some View {
        content.frame(maxWidth: maxReadableWidth())
    }
    
    private func maxReadableWidth() -> CGFloat {
        guard isEnabled else { return 0 }
        
        let idealWidth = 70 * unit / 2
        return idealWidth
    }
}

struct ReducedWidthPadding: ViewModifier {
    let reduction: CGFloat
    let baseModifier: ReadabilityPadding

    func body(content: Content) -> some View {
        // Implement your logic here
    }
}
