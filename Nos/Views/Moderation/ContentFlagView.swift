import SwiftUI

/// Displays pickers for selecting content flag option category, with additional stages shown 
/// based on previous selections.
struct ContentFlagView: View {
    @Binding var selectedFlagOptionCategory: FlagOption?
    var title: String
    var subTitle: String?

    var body: some View {
        ScrollView {
            VStack {
                FlagOptionPickerView(
                    selectedFlag: $selectedFlagOptionCategory,
                    options: FlagOption.flagContentCategories,
                    title: title,
                    subTitle: subTitle
                )
            }
        }
        .background(Color.appBg)
    }
}

#Preview {
    ContentFlagView(selectedFlagOptionCategory: .constant(nil), title: "Title")
}
