import Dependencies
import SwiftUI

/// The Display Name view in the onboarding.
struct DisplayNameView: View {
    @Environment(OnboardingState.self) private var state
    @Environment(CurrentUser.self) private var currentUser
    @Environment(\.managedObjectContext) private var viewContext

    @Dependency(\.crashReporting) private var crashReporting

    @State private var displayName = ""
    @State private var saveError: SaveProfileError?

    private var showAlert: Binding<Bool> {
        Binding {
            saveError != nil
        } set: { _ in
            saveError = nil
        }
    }

    var body: some View {
        ZStack {
            Color.appBg
                .ignoresSafeArea()
            ViewThatFits(in: .vertical) {
                displayNameStack

                ScrollView {
                    displayNameStack
                }
            }
        }
        .navigationBarHidden(true)
        .alert(isPresented: showAlert, error: saveError) {
            Button {
                saveError = nil
                Task {
                    await save()
                }
            } label: {
                Text("retry")
            }
            Button {
                saveError = nil
            } label: {
                Text("cancel")
            }
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
                .textInputAutocapitalization(.none)
                .foregroundStyle(Color.primaryTxt)
                .fontWeight(.bold)
                .autocorrectionDisabled()
                .padding()
                .withStyledBorder()
            Spacer()
            BigActionButton("next") {
                await save()
            }
        }
        .padding(40)
        .readabilityPadding()
    }
    
    /// Saves the display name locally and publishes the event to relays. Sets `saveError` if it fails.
    func save() async {
        guard let author = await currentUser.author else {
            saveError = SaveProfileError.unexpectedError
            return
        }

        author.displayName = displayName
        do {
            try viewContext.save()
            try await currentUser.publishMetadata()
            state.step = .buildYourNetwork
        } catch CurrentUserError.errorWhilePublishingToRelays {
            saveError = SaveProfileError.unableToPublishChanges
        } catch {
            crashReporting.report(error)
            saveError = SaveProfileError.unexpectedError
        }
    }
}

#Preview {
    DisplayNameView()
        .environment(OnboardingState())
        .inject(previewData: PreviewData())
}
