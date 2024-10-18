import SwiftUI

/// A large colorful banner with a message and action button.
struct ActionBanner: View {
    
    var messageText: LocalizedStringKey
    var messageImage: Image?
    var buttonText: LocalizedStringKey
    var buttonImage: Image?
    var shouldButtonFillHorizontalSpace: Bool
    var action: (() -> Void)?

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [.actionBannerBgGradientLeading, .actionBannerBgGradientTrailing],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    var body: some View {
        ZStack {
            Color.actionBannerBg
                .cornerRadius(21)
                .offset(y: 2)
            
            VStack {
                HStack {
                    Text(messageText)
                        .font(.clarity(.bold))
                        .foregroundStyle(Color.white)
                        .lineSpacing(3)
                        .padding(.top, 8)
                        .padding(.bottom, 12)
                        .shadow(radius: 2, y: 1)
                    Spacer()
                }
                HStack {
                    ActionButton(
                        buttonText,
                        font: .clarity(.semibold, textStyle: .subheadline),
                        image: buttonImage,
                        textColor: .actionBannerButtonTxt,
                        depthEffectColor: .actionBannerButtonEffect,
                        backgroundGradient: LinearGradient(
                            colors: [.actionBannerButtonGradientLeading, .actionBannerButtonGradientTrailing],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        textShadow: false,
                        shouldFillHorizontalSpace: shouldButtonFillHorizontalSpace
                    ) {
                        action?()
                    }
                    .frame(minHeight: 40)
                    if !shouldButtonFillHorizontalSpace {
                        Spacer()
                    }
                }
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 24)
            .background {
                if let image = messageImage {
                    HStack {
                        Spacer()
                        image
                            .aspectRatio(1, contentMode: .fit)
                            .blendMode(.softLight)
                    }
                    .offset(x: 28)
                } else {
                    EmptyView()
                }
            }
            .background(
                ZStack {
                    ZStack {
                        LinearGradient(
                            colors: [
                                Color.actionBannerBackgroundGradientTop,
                                Color.actionBannerBackgroundGradientBottom,
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .blendMode(.softLight)
                        
                        backgroundGradient.blendMode(.normal)
                    }
                }
                    .offset(y: -2)
            )
            .cornerRadius(20)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct ActionBanner_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ActionBanner(
                messageText: "completeProfileMessage",
                messageImage: Image.atSymbol,
                buttonText: "completeProfileButton",
                shouldButtonFillHorizontalSpace: true
            )
            .padding(20)
        }
        .background(Color.appBg)
    }
}
