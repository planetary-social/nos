import SwiftUI

/// Displays pickers for selecting content flag option category, with additional stages shown
/// based on previous selections.
struct ContentFlagView: View {
    @Binding var selectedFlagOptionCategory: FlagOption?
    @Binding var selectedSendOptionCategory: FlagOption?

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                FlagOptionPicker(
                    selectedOption: $selectedFlagOptionCategory,
                    options: FlagOption.flagContentCategories,
                    title: String(localized: .localizable.flagContentCategoryTitle),
                    subtitle: String(localized: .localizable.flagContentCategoryDescription)
                )

                if selectedFlagOptionCategory != nil {
                    FlagOptionPicker(
                        selectedOption: $selectedSendOptionCategory,
                        options: FlagOption.flagContentSendCategories,
                        title: String(localized: .localizable.flagContentSendTitle),
                        subtitle: nil
                    )
                }
            }
        }
        .padding()
        .background(Color.appBg)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedFlagOptionCategory: FlagOption?
        @State private var selectedSendOptionCategory: FlagOption?

        var body: some View {
            ContentFlagView(
                selectedFlagOptionCategory: $selectedFlagOptionCategory,
                selectedSendOptionCategory: $selectedSendOptionCategory
            )
            .onAppear {
                selectedFlagOptionCategory = nil
            }
            .background(Color.appBg)
        }
    }
    return PreviewWrapper()
}
