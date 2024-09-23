import SwiftUI

struct SetUpUNSBanner: View {

    var text: LocalizedStringResource
    var button: LocalizedStringResource

    var action: (() -> Void)?

    var body: some View {
        ZStack {
            Color.card3d
                .cornerRadius(21)
                .offset(y: 2)
            VStack {
                HStack {
                    Text(text)
                        .font(.body)
                        .foregroundStyle(Color.primaryTxt)
                        .lineSpacing(3)
                        .padding(.top, 8)
                        .padding(.bottom, 12)
                        .padding(.leading, 4)
                        .foregroundColor(.white)
                    Spacer()
                }
                
                HStack {
                    ActionButton(
                        title: button,
                        font: .clarity(.semibold, textStyle: .subheadline),
                        textColor: .unsBannerButtonTxt,
                        depthEffectColor: .unsBannerButtonEffect,
                        backgroundGradient: LinearGradient(
                            colors: [.unsButtonGradientTop, .unsButtonGradientBottom],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        textShadow: false
                    ) {
                        action?()
                    }
                    .frame(minHeight: 40)
                    Spacer()
                }
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 24)
            .background(
                ZStack {
                    ZStack {
                        LinearGradient.cardGradient
                    }
                }
                .offset(y: -2)
            )
            
            .cornerRadius(20)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct SetUpUNSBanner_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            SetUpUNSBanner(
                text: .localizable.unsTagline,
                button: .localizable.manageUniversalName
            )
            .padding(20)
        }
        .background(Color.appBg)
    }
}
