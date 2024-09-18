import SwiftUI

/// Displays pickers for selecting content flag option category, with additional stages shown 
/// based on previous selections.
struct ContentFlagView: View {
    @Binding var selectedFlagOptionCategory: FlagOption?
    var title: String
    var subtitle: String?

    var body: some View {
        ScrollView {
            VStack {
                FlagOptionPicker(
                    selectedOption: $selectedFlagOptionCategory,
                    options: FlagOption.flagContentCategories,
                    title: title,
                    subtitle: subtitle
                )
            }
        }
        .background(Color.appBg)
    }
}

#Preview {
    ContentFlagView(selectedFlagOptionCategory: .constant(nil), title: "Title")
}
