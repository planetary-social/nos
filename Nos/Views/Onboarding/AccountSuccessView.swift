import Dependencies
import SwiftUI

/// The Account Success view in the onboarding.
struct AccountSuccessView: View {
    @Environment(OnboardingState.self) private var state
    @Environment(CurrentUser.self) var currentUser

    @Dependency(\.crashReporting) private var crashReporting

    var body: some View {
        ZStack {
            Color.appBg
                .ignoresSafeArea()
            ViewThatFits(in: .vertical) {
                accountSuccessStack

                ScrollView {
                    accountSuccessStack
                }
            }
        }
        .navigationBarHidden(true)
    }

    var accountSuccessStack: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(emoji)
                .font(.system(size: 60))
            Text(headline)
                .font(.clarityBold(.title))
                .foregroundStyle(Color.primaryTxt)
                .padding(.bottom, 10)
            CompletedStepsView(state)
                .padding(.horizontal, 10)
            Spacer()
            Text(description)
                .foregroundStyle(Color.secondaryTxt)
            BigActionButton("next") {
                state.step = .buildYourNetwork
            }
        }
        .padding(40)
        .readabilityPadding()
    }

    var emoji: String {
        state.allStepsSucceeded ? "🎉" : "🤔"
    }

    var headline: LocalizedStringKey {
        state.allStepsSucceeded ? "accountSuccessHeadline" : "accountPartialSuccessHeadline"
    }

    var description: LocalizedStringKey {
        state.allStepsSucceeded ? "accountSuccessDescription" : "accountPartialSuccessDescription"
    }
}

/// The four numbered steps with their corresponding text.
fileprivate struct CompletedStepsView: View {
    let state: OnboardingState

    init(_ state: OnboardingState) {
        self.state = state
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 50) {
            StepView(completed: true, label: "privateKeyHeadline")
            StepView(completed: true, label: "publicKeyHeadline")
            StepView(completed: state.displayNameSucceeded, label: "displayNameHeadline")
            StepView(completed: state.usernameSucceeded, label: "usernameHeadline")
        }
        .background(
            ConnectingLine()
                .offset(x: 8)
                .stroke(Color.numberedStepBackground, lineWidth: 4),
            alignment: .leading
        )
    }
}

/// A view containing an index with a circle background and some text.
fileprivate struct StepView: View {
    let completed: Bool
    let label: LocalizedStringKey

    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            Group {
                if completed {
                    Image(systemName: "checkmark")
                } else {
                    Image(systemName: "xmark")
                }
            }
            .fontWeight(.bold)
            .foregroundStyle(Color.primaryTxt)
            .frame(width: 16)
            .background(
                Group {
                    if completed {
                        Circle()
                            .fill(LinearGradient.verticalAccentPrimary)
                    } else {
                        Circle()
                            .fill(Color.numberedStepBackground)
                    }
                }
                    .frame(width: 30, height: 30)
            )

            Text(label)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(Color.primaryTxt)
        }
    }
}

/// Custom shape for the vertical connecting line
fileprivate struct ConnectingLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let startPoint = CGPoint(x: rect.minX, y: 0)
        let endPoint = CGPoint(x: rect.minX, y: rect.maxY)

        path.move(to: startPoint)
        path.addLine(to: endPoint)

        return path
    }
}

#Preview("All steps completed") {
    var state = OnboardingState()
    state.displayNameSucceeded = true
    state.usernameSucceeded = true

    return AccountSuccessView()
        .environment(state)
        .inject(previewData: PreviewData())
}

#Preview("Some steps failed") {
    AccountSuccessView()
        .environment(OnboardingState())
        .inject(previewData: PreviewData())
}
