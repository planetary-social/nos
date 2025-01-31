import Dependencies
import SwiftUI

/// The Display Name view in the onboarding.
struct DisplayNameView: View {
    @Environment(OnboardingState.self) private var state
    @Environment(CurrentUser.self) private var currentUser
    @Environment(\.managedObjectContext) private var viewContext
    @FocusState private var isTextFieldFocused: Bool

    @Dependency(\.crashReporting) private var crashReporting

    @State private var displayName = ""
    @State private var showError: Bool = false

    var body: some View {
        ZStack {
            Color.appBg
                .ignoresSafeArea()
            ViewThatFits {
                displayNameStack

                ScrollView {
                    displayNameStack
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            isTextFieldFocused = true
        }
        .ignoresSafeArea(.keyboard)
        .interactiveDismissDisabled()
        .alert("", isPresented: $showError) {
            Button {
                nextStep()
            } label: {
                Text("skipForNow")
            }
        } message: {
            Text("errorConnecting")
        }
    }

    var displayNameStack: some View {
        VStack(alignment: .leading, spacing: 20) {
            LargeNumberView(3)
            Text("displayNameHeadline")
                .font(.clarityBold(.title))
                .foregroundStyle(Color.primaryTxt)
            Text("displayNameDescription")
                .font(.body)
                .foregroundStyle(Color.secondaryTxt)
            TextField(
                "",
                text: $displayName,
                prompt: Text("displayNamePlaceholder")
                    .foregroundStyle(Color.textFieldPlaceholder)
            )
                .textInputAutocapitalization(.never)
                .foregroundStyle(Color.primaryTxt)
                .fontWeight(.bold)
                .autocorrectionDisabled()
                .focused($isTextFieldFocused)
                .padding()
                .withStyledBorder()
            Spacer()
            BigActionButton("next") {
                await save()
            }
            .disabled(displayName.isEmpty)
        }
        .padding(40)
        .readabilityPadding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    func nextStep() {
        state.step = .username
    }

    /// Saves the display name locally and publishes the event to relays. Sets `showError` if it fails.
    func save() async {
        guard let author = await currentUser.author else {
            showError = true
            return
        }

        author.displayName = displayName
        do {
            try viewContext.save()
            try await currentUser.publishMetadata()
            state.displayNameSucceeded = true
            nextStep()
        } catch {
            crashReporting.report(error)
            showError = true
        }
    }
}

#Preview {
    DisplayNameView()
        .environment(OnboardingState())
        .inject(previewData: PreviewData())
}
