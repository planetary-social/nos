import SwiftUI

/// Displays a placeholder text when required.
/// - Parameters:
///   - show: A Boolean indicating whether to show the placeholder.
///   - placeholder: The text to display as the placeholder.
///   - placeholderColor: The color of the placeholder.
///   - font: The font type of the placeholder.
struct PlaceholderStyle: ViewModifier {
    var show: Bool
    var placeholder: String
    var placeholderColor: Color = .actionSheetTextfieldPlaceholder
    var font: Font = .headline

    /// Displays the placeholder text if `show` is true, overlaying it
    /// on the content view.
    func body(content: Content) -> some View {
        ZStack(alignment: .leading) {
            if show {
                Text(placeholder)
                    .foregroundColor(placeholderColor)
                    .padding(.leading, 9)
                    .font(font)
                    .fontWeight(.bold)
            }
            content
                .foregroundColor(Color.white)
                .font(.headline)
                .fontWeight(.bold)
        }
    }
}
