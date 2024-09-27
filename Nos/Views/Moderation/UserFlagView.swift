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

    /// Controls whether the "Send Section" should slide in from the left.
    @State private var slideInSendSection = false

    /// Controls whether the "Visibility Section" should slide in from the left.
    @State private var slideInVisibilitySection = false

    /// Used to identify the "Send Section" section to autoscroll to the when it appears.
    @Namespace var sendSectionID

    /// Used to identify the "Visibility Section" section to autoscroll to the when it appears.
    @Namespace var visibilitySectionID

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
        slideInSendSection = false
        slideInVisibilitySection = false
    }

    private var categoryView: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
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
                        .id(sendSectionID)
                        .offset(x: slideInSendSection ? 0 : -UIScreen.main.bounds.width)
                    }

                    if selectedSendOptionCategory != nil {
                        FlagOptionPicker(
                            previousSelection: .constant(nil),
                            currentSelection: $selectedVisibilityOptionCategory,
                            options: FlagOption.flagUserVisibilityOptions,
                            title: String(localized: .localizable.flagUserMuteCategoryTitle),
                            subtitle: nil
                        )
                        .id(visibilitySectionID)
                        .offset(x: slideInVisibilitySection ? 0 : -UIScreen.main.bounds.width)
                    }
                }
                .padding()
                .onChange(of: selectedFlagOptionCategory) {
                    animateAndScrollTo(
                        targetSectionID: sendSectionID,
                        shouldSlideIn: $slideInSendSection,
                        proxy: proxy
                    )
                }
                .onChange(of: selectedSendOptionCategory) {
                    animateAndScrollTo(
                        targetSectionID: visibilitySectionID,
                        shouldSlideIn: $slideInVisibilitySection,
                        proxy: proxy
                    )
                }
            }
        }
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
