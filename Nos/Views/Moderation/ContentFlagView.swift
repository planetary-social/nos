import SwiftUI

/// Displays pickers for selecting content flag option category, with additional stages shown 
/// based on previous selections.
struct ContentFlagView: View {
    @Binding var selectedFlagOptionCategory: FlagOption?

    var body: some View {
        ScrollView {
            VStack {
                FlagOptionPicker(
                    selectedOption: $selectedFlagOptionCategory,
                    options: FlagOption.flagContentCategories,
                    title: String(localized: .localizable.flagContentCategoryTitle),
                    subtitle: String(localized: .localizable.flagContentCategoryDescription)
                )
            }
        }
        .background(Color.appBg)
    }
}

#Preview {
    ContentFlagView(selectedFlagOptionCategory: .constant(nil))
}
