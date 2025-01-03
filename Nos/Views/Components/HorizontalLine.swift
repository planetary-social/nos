import SwiftUI

/// A thin horizontal line with the provided color.
///
/// The default thickness of the line is 1 point, but it can be overridden,
/// such as to make it 1 pixel (e.g. `1 / UIScreen.main.scale`).
struct HorizontalLine: View {
    let color: Color
    var height: CGFloat = 1
    
    var body: some View {
        Rectangle()
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .foregroundStyle(color)
    }
}
