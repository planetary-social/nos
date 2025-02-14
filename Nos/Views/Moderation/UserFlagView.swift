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
    let sendAction: () -> Void

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

    /// Controls when the "Send Section" should slide in from the left.
    @State private var animateSendSection = false

    /// Controls when the "Visibility Section" should slide in from the left.
    @State private var animateVisibilitySection = false

    /// Used to identify the "Send Section" section to autoscroll to the when it appears.
    @Namespace var sendSectionID

    /// Used to identify the "Visibility Section" section to autoscroll to the when it appears.
    @Namespace var visibilitySectionID

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
            .nosNavigationBar("flagUserTitle")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                        resetSelections()
                    } label: {
                        Text("cancel")
                            .foregroundColor(.primaryTxt)
                    }
                    .opacity(showSuccessView ? 0 : 1)
                    .disabled(showSuccessView)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    ActionButton(
                        showSuccessView ? "done" : "send",
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
        animateSendSection = false
        animateVisibilitySection = false
    }

    private var categoryView: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
                        FlagOptionPicker(
                            previousSelection: .constant(nil),
                            currentSelection: $selectedFlagOption,
                            options: flagCategories,
                            title: String(localized: "flagUserCategoryTitle"),
                            subtitle: String(localized: "flagUserCategoryDescription")
                        )

                        if selectedFlagOption != nil {
                            FlagOptionPicker(
                                previousSelection: $selectedFlagOption,
                                currentSelection: $selectedSendOption,
                                options: FlagOption.flagUserSendOptions,
                                title: String(localized: "flagSendTitle"),
                                subtitle: nil
                            )
                            .id(sendSectionID)
                            .offset(x: animateSendSection ? 0 : -geometry.size.width)
                        }

                        if selectedSendOption != nil && !isUserMuted {
                            FlagOptionPicker(
                                previousSelection: .constant(nil),
                                currentSelection: $selectedVisibilityOption,
                                options: FlagOption.flagUserVisibilityOptions,
                                title: String(localized: "flagUserMuteCategoryTitle"),
                                subtitle: nil
                            )
                            .id(visibilitySectionID)
                            .offset(x: animateVisibilitySection ? 0 : -geometry.size.width)
                        }
                    }
                    .padding()
                    .onChange(of: selectedFlagOption) {
                        /// Animates the sliding effect and scrolls to the bottom of the specified section.
                        proxy.animateAndScrollTo(sendSectionID, animating: $animateSendSection)
                    }
                    .onChange(of: selectedSendOption) {
                        /// Animates the sliding effect and scrolls to the bottom of the specified section.
                        proxy.animateAndScrollTo(visibilitySectionID, animating: $animateVisibilitySection)
                    }
                }
            }
        }
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
