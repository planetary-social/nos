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
            .animation(.easeInOut, value: selectedFlagOptionCategory)
            .padding()
            .nosNavigationBar(title: .localizable.flagContent)
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
                    .opacity(selectedSendOptionCategory == nil ? 0.5 : 1)
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
    }

    private var categoryView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 30) {
                FlagOptionPicker(
                    previousSelection: .constant(nil),
                    currentSelection: $selectedFlagOptionCategory,
                    options: flagCategories,
                    title: String(localized: .localizable.flagContentCategoryTitle),
                    subtitle: String(localized: .localizable.flagContentCategoryDescription)
                )

                if selectedFlagOptionCategory != nil {
                    FlagOptionPicker(
                        previousSelection: $selectedFlagOptionCategory,
                        currentSelection: $selectedSendOptionCategory,
                        options: FlagOption.flagContentSendOptions,
                        title: String(localized: .localizable.flagSendTitle),
                        subtitle: nil
                    )
                    .transition(.move(edge: .leading).combined(with: .opacity))
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
