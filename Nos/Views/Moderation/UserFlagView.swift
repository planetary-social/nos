import SwiftUI

/// Displays pickers for selecting user flag options, with additional stages shown
/// based on previous selections.
struct UserFlagView: View {
    @Binding var selectedFlagOption: FlagOption?
    @Binding var selectedSendOption: FlagOption?
    @Binding var selectedVisibilityOption: FlagOption?
    @Binding var showSuccessView: Bool

    /// The target of the report.
    let flagTarget: ReportTarget

    /// Defines the action to be performed when the user sends a flag report.
    /// It is called when the user taps the "Send" button after selecting all required options.
    var sendAction: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var flagCategories: [FlagOption] = []

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
                    .opacity(selectedVisibilityOption == nil ? 0.5 : 1)
                    .disabled(selectedVisibilityOption == nil)
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
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
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
                        .id(sendSectionID)
                        .offset(x: animateSendSection ? 0 : -UIScreen.main.bounds.width)
                    }

                    if selectedSendOption != nil {
                        FlagOptionPicker(
                            previousSelection: .constant(nil),
                            currentSelection: $selectedVisibilityOption,
                            options: FlagOption.flagUserVisibilityOptions,
                            title: String(localized: .localizable.flagUserMuteCategoryTitle),
                            subtitle: nil
                        )
                        .id(visibilitySectionID)
                        .offset(x: animateVisibilitySection ? 0 : -UIScreen.main.bounds.width)
                    }
                }
                .padding()
                .onChange(of: selectedFlagOption) {
                    animateAndScrollTo(
                        targetSectionID: sendSectionID,
                        shouldSlideIn: $animateSendSection,
                        proxy: proxy
                    )
                }
                .onChange(of: selectedSendOption) {
                    animateAndScrollTo(
                        targetSectionID: visibilitySectionID,
                        shouldSlideIn: $animateVisibilitySection,
                        proxy: proxy
                    )
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
