import SwiftUI

/// Displays pickers for selecting content flag option category, with additional stages shown
/// based on previous selections.
struct ContentFlagView: View {
    @Binding var selectedFlagOptionCategory: FlagOption?
    @Binding var selectedSendOptionCategory: FlagOption?
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

    /// Used to identify the "Send Section" section to autoscroll to the when it appears.
    @Namespace var sendSectionID

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
            .nosNavigationBar("flagContent")
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
                    .disabled(selectedSendOptionCategory == nil)
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
        animateSendSection = false
    }

    private var categoryView: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
                        FlagOptionPicker(
                            previousSelection: .constant(nil),
                            currentSelection: $selectedFlagOptionCategory,
                            options: flagCategories,
                            title: String(localized: "flagContentCategoryTitle"),
                            subtitle: String(localized: "flagContentCategoryDescription")
                        )

                        if selectedFlagOptionCategory != nil {
                            FlagOptionPicker(
                                previousSelection: $selectedFlagOptionCategory,
                                currentSelection: $selectedSendOptionCategory,
                                options: FlagOption.flagContentSendOptions,
                                title: String(localized: "flagSendTitle"),
                                subtitle: nil
                            )
                            .id(sendSectionID)
                            .offset(x: animateSendSection ? 0 : -geometry.size.width)
                        }
                    }
                    .padding()
                    .onChange(of: selectedFlagOptionCategory) {
                        /// Animates the sliding effect and scrolls to the bottom of the specified section.
                        proxy.animateAndScrollTo(sendSectionID, animating: $animateSendSection)
                    }
                }
            }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedFlagOptionCategory: FlagOption?
        @State private var selectedSendOptionCategory: FlagOption?
        @State private var showSuccessView = false
        let event = Event()

        var body: some View {
            NavigationStack {
                ContentFlagView(
                    selectedFlagOptionCategory: $selectedFlagOptionCategory,
                    selectedSendOptionCategory: $selectedSendOptionCategory,
                    showSuccessView: $showSuccessView, 
                    flagTarget: .note(event),
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
