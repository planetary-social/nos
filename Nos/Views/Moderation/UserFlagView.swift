import SwiftUI

/// Displays pickers for selecting user flag options, with additional stages shown
/// based on previous selections.
struct UserFlagView: View {
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
                    previousSelection: .constant(nil),
                    currentSelection: $selectedFlagOptionCategory,
                    options: flagCategories,
                    title: String(localized: .localizable.flagUserCategoryTitle),
                    subtitle: String(localized: .localizable.flagUserCategoryDescription)
                )

                if selectedFlagOptionCategory != nil {
                    FlagOptionPicker(
                        previousSelection: $selectedFlagOptionCategory,
                        currentSelection: $selectedSendOptionCategory,
                        options: FlagOption.flagUserSendOptions,
                        title: String(localized: .localizable.flagSendTitle),
                        subtitle: nil
                    )
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }

                if selectedSendOptionCategory != nil {
                    FlagOptionPicker(
                        previousSelection: .constant(nil),
                        currentSelection: $selectedVisibilityOptionCategory,
                        options: FlagOption.flagUserVisibilityOptions,
                        title: String(localized: .localizable.flagUserMuteCategoryTitle),
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
                UserFlagView(
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
