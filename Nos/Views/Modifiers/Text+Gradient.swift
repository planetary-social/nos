import SwiftUI

extension Text {
    
    /// Colors the text with the given gradient
    public func foregroundLinearGradient(_ gradient: LinearGradient) -> some View {
        self.overlay {
            gradient.mask(
                self
            )
        }
    }
}
