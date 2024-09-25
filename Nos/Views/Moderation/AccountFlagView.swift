import SwiftUI

/// Displays pickers for selecting account flag option category, with additional stages shown
/// based on previous selections.
struct AccountFlagView: View {
    @Binding var selectedFlagOptionCategory: FlagOption?
    @Binding var selectedSendOptionCategory: FlagOption?
    @Binding var selectedVisibilityOptionCategory: FlagOption?
    @Binding var showSuccessView: Bool

    /// The target of the report.
    let flagTarget: ReportTarget
    var sendAction: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var flagCategories: [FlagOption] = []

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
            .padding()
            .nosNavigationBar(title: .localizable.flagUserTitle)
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
                    .opacity(selectedVisibilityOptionCategory == nil ? 0.5 : 1)
                    .disabled(selectedVisibilityOptionCategory == nil)
                }
            }
        }
        .onAppear {
            flagCategories = FlagOption.createFlagCategories(for: flagTarget)
        }
    }

    private func resetSelections() {
        selectedFlagOptionCategory = nil
        selectedSendOptionCategory = nil
        selectedVisibilityOptionCategory = nil
    }

    private var categoryView: some View {
        ScrollView {
            VStack(spacing: 30) {
                FlagOptionPicker(
                    selectedOption: $selectedFlagOptionCategory,
                    options: flagCategories,
                    title: String(localized: .localizable.flagAccountCategoryTitle),
                    subtitle: String(localized: .localizable.flagAccountCategoryDescription)
                )

                if selectedFlagOptionCategory != nil {
                    FlagOptionPicker(
                        selectedOption: $selectedSendOptionCategory,
                        options: FlagOption.flagAccountSendCategories,
                        title: String(localized: .localizable.flagContentSendTitle),
                        subtitle: nil
                    )
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }

                if selectedSendOptionCategory != nil {
                    FlagOptionPicker(
                        selectedOption: $selectedVisibilityOptionCategory,
                        options: FlagOption.flagAccountVisibilityCategories,
                        title: String(localized: .localizable.flagAccountMuteCategoryTitle),
                        subtitle: nil
                    )
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }
            }
        }
        .animation(.easeInOut, value: selectedFlagOptionCategory)
        .animation(.easeInOut, value: selectedSendOptionCategory)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedFlagOptionCategory: FlagOption?
        @State private var selectedSendOptionCategory: FlagOption?
        @State private var selectedVisibilityOptionCategory: FlagOption?
        @State private var showSuccessView = false
        let author = Author()

        var body: some View {
            NavigationStack {
                AccountFlagView(
                    selectedFlagOptionCategory: $selectedFlagOptionCategory,
                    selectedSendOptionCategory: $selectedSendOptionCategory,
                    selectedVisibilityOptionCategory: $selectedVisibilityOptionCategory,
                    showSuccessView: $showSuccessView,
                    flagTarget: .author(author),
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
