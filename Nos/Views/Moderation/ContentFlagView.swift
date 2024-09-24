import SwiftUI

/// Displays pickers for selecting content flag option category, with additional stages shown
/// based on previous selections.
struct ContentFlagView: View {
    @Binding var selectedFlagOptionCategory: FlagOption?
    @Binding var selectedSendOptionCategory: FlagOption?
    @Binding var showSuccessView: Bool
    var sendAction: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()
            Group {
                if showSuccessView {
                    flagSuccessView
                } else {
                    categoryView
                }
            }
            .animation(.easeInOut, value: selectedFlagOptionCategory)
            .padding()
            .nosNavigationBar(title: .localizable.flagContent)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                        resetSelections()
                    }, label: {
                        Text(.localizable.cancel)
                            .foregroundColor(.primaryTxt)
                    })
                    .opacity(showSuccessView ? 0 : 1)
                    .disabled(showSuccessView)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    ActionButton(
                        title: showSuccessView ? .localizable.done : .localizable.send,
                        action: {
                            if showSuccessView {
                                dismiss()
                                resetSelections()
                                showSuccessView = false
                            } else {
                                sendAction()
                            }
                        }
                    )
                    .opacity(selectedSendOptionCategory == nil ? 0.5 : 1)
                    .disabled(selectedSendOptionCategory == nil)
                }
            }
        }
    }

    private func resetSelections() {
        selectedFlagOptionCategory = nil
        selectedSendOptionCategory = nil
    }

    private var categoryView: some View {
        ScrollView(showsIndicators: false) {
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
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }
            }
        }
    }
}

var flagSuccessView: some View {
    VStack(spacing: 30) {
        Image.circularCheckmark
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: 116)

        Text(String(localized: .localizable.thanksForTag))
            .foregroundColor(.primaryTxt)
            .font(.clarity(.regular, textStyle: .title2))
            .padding(.horizontal, 62)

        Text(String(localized: .localizable.keepOnHelpingUs))
            .padding(.horizontal, 68)
            .foregroundColor(.secondaryTxt)
            .multilineTextAlignment(.center)
            .lineSpacing(6)
            .font(.clarity(.regular, textStyle: .subheadline))
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedFlagOptionCategory: FlagOption?
        @State private var selectedSendOptionCategory: FlagOption?
        @State private var showSuccessView = true

        var body: some View {
            NavigationStack {
                ContentFlagView(
                    selectedFlagOptionCategory: $selectedFlagOptionCategory,
                    selectedSendOptionCategory: $selectedSendOptionCategory,
                    showSuccessView: $showSuccessView,
                    sendAction: {}
                )
            }
            .onAppear {
                selectedFlagOptionCategory = nil
            }
            .background(Color.appBg)
        }
    }
    return PreviewWrapper()
}
