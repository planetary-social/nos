import SwiftUI

/// Displays a placeholder text when required.
/// - Parameters:
///   - show: A Boolean indicating whether to show the placeholder.
///   - placeholder: The text to display as the placeholder.
struct PlaceholderStyle: ViewModifier {
    var show: Bool
    var placeholder: String

    /// Displays the placeholder text if `show` is true, overlaying it
    /// on the content view.
    func body(content: Content) -> some View {
        ZStack(alignment: .leading) {
            if show {
                Text(placeholder)
                    .foregroundColor(Color.actionSheetTextfieldPlaceholder)
                    .padding(.leading, 9)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            content
                .foregroundColor(Color.white)
                .font(.headline)
                .fontWeight(.bold)
        }
    }
}
