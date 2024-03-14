import SwiftUI

extension Text {
    
    /// Colors the text with the given gradient
    public func foregroundLinearGradient(colors: [Color], startPoint: UnitPoint, endPoint: UnitPoint) -> some View {
        foregroundLinearGradient(
            LinearGradient(
                colors: colors,
                startPoint: startPoint,
                endPoint: endPoint
            )
        )
    }
    
    /// Colors the text with the given gradient
    public func foregroundLinearGradient(_ gradient: LinearGradient) -> some View {
        self.overlay {
            gradient.mask(
                self
            )
        }
    }
}
