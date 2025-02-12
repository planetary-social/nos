import Foundation
import SwiftUI

extension View {
    func readabilityPadding(isEnabled: Bool = true) -> some View {
        modifier(ReadabilityPadding(isEnabled: isEnabled))
    }
}

// Based on https://stackoverflow.com/a/68478487/982195
fileprivate struct ReadabilityPadding: ViewModifier {
    let isEnabled: Bool
    @ScaledMetric private var unit: CGFloat = 20
    
    func body(content: Content) -> some View {
        content.frame(maxWidth: maxReadableWidth())
    }
    
    private func maxReadableWidth() -> CGFloat {
        guard isEnabled else { return 0 }
        
        // The internet seems to think the optimal readable width is 50-75
        // characters wide; I chose 70 here. The `unit` variable is the 
        // approximate size of the system font and is wrapped in
        // @ScaledMetric to better support dynamic type. I assume that 
        // the average character width is half of the size of the font. 
        let idealWidth = 70 * unit / 2
        return idealWidth
    }
}
