import Dependencies
import SwiftUI

struct UNSNameTakenView: View {

    @ObservedObject var controller: UNSWizardController
    @Dependency(\.analytics) var analytics

    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    UNSStepImage { Image.unsNameTaken.offset(x: 7, y: 5) }
                        .padding(40)
                        .padding(.top, 50)

                    Text(.localizable.oops)
                        .font(.clarityBold(.title))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primaryTxt)
                        .shadow(radius: 1, y: 1)
                        .padding(.top, 20)
                        .padding(.bottom, 3)

                    Text(.localizable.thatNameIsTaken)
                        .font(.clarityBold(.title))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primaryTxt)
                        .shadow(radius: 1, y: 1)
                        .padding(.bottom, 20)

                    Text(.localizable.tryAnotherName)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondaryTxt)
                        .padding(.vertical, 17)
                        .padding(.horizontal, 20)
                        .shadow(radius: 1, y: 1)
                        .padding(.bottom, 20)
                }

                Spacer()

                BigActionButton(title: .localizable.goBack) {
                    switch controller.state {
                    case .nameTaken(let previousState):
                        controller.state = previousState
                    default:
                        controller.state = .error(nil)
                    }
                }
                .padding(.bottom, 41)
            }
            .padding(.horizontal, 38)
            .readabilityPadding()
            .background(Color.appBg)
            .onAppear {
                analytics.choseInvalidUNSName()
            }
        }
    }
}

#Preview {
    @State var controller = UNSWizardController(state: .newName)

    return UNSNameTakenView(controller: controller)
}
