import SwiftUI

/// Displays pickers for selecting user flag options, with additional stages shown
/// based on previous selections.
struct UserFlagView: View {
    @Binding var selectedFlagOption: FlagOption?
    @Binding var selectedSendOption: FlagOption?
    @Binding var selectedVisibilityOption: FlagOption?
    @Binding var showSuccessView: Bool

    @Environment(\.dismiss) private var dismiss

    @State private var flagCategories: [FlagOption] = []

    /// The target of the report.
    let flagTarget: ReportTarget

    /// Defines the action to be performed when the user sends a flag report.
    /// It is called when the user taps the "Send" button after selecting all required options.
    var sendAction: () -> Void

    /// Indicates whether the target of the report is muted.
    var isUserMuted: Bool {
        flagTarget.author?.muted ?? false
    }

    /// Determines if the send button should be disabled.
    ///
    /// The button's disabled state depends on two factors:
    /// - For muted users: disabled when no send option is selected.
    /// - For non-muted users: disabled when no visibility option is selected.
    var isSendButtonDisabled: Bool {
        if isUserMuted {
            return selectedSendOption == nil
        }
        return selectedVisibilityOption == nil
    }

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()
            Group {
                if showSuccessView {
                    FlagSuccessView()
                } else {
                    categoryView
                }
            }
            .padding()
            .nosNavigationBar(title: .localizable.flagUserTitle)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                        resetSelections()
                    } label: {
                        Text(.localizable.cancel)
                            .foregroundColor(.primaryTxt)
                    }
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
                    .disabled(isSendButtonDisabled)
                }
            }
        }
        .onAppear {
            flagCategories = FlagOption.createFlagCategories(for: flagTarget)
        }
    }

    private func resetSelections() {
        selectedFlagOption = nil
        selectedSendOption = nil
        selectedVisibilityOption = nil
    }

    private var categoryView: some View {
        ScrollView {
            VStack(spacing: 30) {
                FlagOptionPicker(
                    previousSelection: .constant(nil),
                    currentSelection: $selectedFlagOption,
                    options: flagCategories,
                    title: String(localized: .localizable.flagUserCategoryTitle),
                    subtitle: String(localized: .localizable.flagUserCategoryDescription)
                )

                if selectedFlagOption != nil {
                    FlagOptionPicker(
                        previousSelection: $selectedFlagOption,
                        currentSelection: $selectedSendOption,
                        options: FlagOption.flagUserSendOptions,
                        title: String(localized: .localizable.flagSendTitle),
                        subtitle: nil
                    )
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }

                if selectedSendOption != nil && !isUserMuted {
                    FlagOptionPicker(
                        previousSelection: .constant(nil),
                        currentSelection: $selectedVisibilityOption,
                        options: FlagOption.flagUserVisibilityOptions,
                        title: String(localized: .localizable.flagUserMuteCategoryTitle),
                        subtitle: nil
                    )
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }
            }
        }
        .animation(.easeInOut, value: selectedFlagOption)
        .animation(.easeInOut, value: selectedSendOption)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedFlagOption: FlagOption?
        @State private var selectedSendOption: FlagOption?
        @State private var selectedVisibilityOption: FlagOption?
        @State private var showSuccessView = false
        let author = Author()

        var body: some View {
            NavigationStack {
                UserFlagView(
                    selectedFlagOption: $selectedFlagOption,
                    selectedSendOption: $selectedSendOption,
                    selectedVisibilityOption: $selectedVisibilityOption,
                    showSuccessView: $showSuccessView,
                    flagTarget: .author(author),
                    sendAction: {}
                )
            }
            .onAppear {
                selectedFlagOption = nil
            }
            .background(Color.appBg)
        }
    }
    return PreviewWrapper()
}
