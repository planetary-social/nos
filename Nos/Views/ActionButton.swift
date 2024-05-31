import SwiftUI

/// A big bright button that is used as the primary call-to-action on a screen.
struct ActionButton: View {
    
    enum ImageAlignment {
        case left
        case right
    }

    var title: LocalizedStringResource
    var font: Font = .clarity(.bold)
    var image: Image?
    var imageAlignment: ImageAlignment = .left
    var textColor = Color.white
    var depthEffectColor = Color(hex: "#A04651")
    var backgroundGradient = LinearGradient(
        colors: [
            Color.actionPrimaryGradientTop,
            Color.actionPrimaryGradientBottom
        ],
        startPoint: .bottomLeading,
        endPoint: .topTrailing
    )
    var textShadow = true
    /// A flag used to fill the available horizontal space (centering the
    /// contents) or to fit the horizontal space to the contents of the action
    /// button.
    var shouldFillHorizontalSpace = false
    var action: (() async -> Void)?
    @State var disabled = false
    
    var body: some View {
        Button(action: {
            disabled = true
            Task {
                await action?()
                disabled = false
            }
        }, label: {
            HStack(spacing: 4) {
                if shouldFillHorizontalSpace {
                    // Center the image+text if the button has to fill the
                    // available space.
                    Spacer(minLength: 0)
                }
                if imageAlignment == .left {
                    image
                }
                Text(title)
                    .font(font)
                    .transition(.opacity)
                    .font(.headline)
                    .foregroundColor(textColor)
                if imageAlignment == .right {
                    image
                }
                if shouldFillHorizontalSpace {
                    // Center the image+text if the button has to fill the
                    // available space.
                    Spacer(minLength: 0)
                }
            }
        })
        .lineLimit(nil)
        .foregroundColor(.black)
        .buttonStyle(ActionButtonStyle(
            depthEffectColor: depthEffectColor,
            backgroundGradient: backgroundGradient,
            textShadow: textShadow,
            shouldFillHorizontalSpace: shouldFillHorizontalSpace
        ))
        .disabled(disabled)
    }
}

struct SecondaryActionButton: View {
    var title: LocalizedStringResource
    var image: Image?
    var imageAlignment: ActionButton.ImageAlignment = .left
    /// A flag used to fill the available horizontal space (centering the
    /// contents) or to fit the horizontal space to the contents of the action
    /// button.
    var shouldFillHorizontalSpace = false
    var action: (() async -> Void)?
    
    var body: some View {
        ActionButton(
            title: title,
            image: image,
            imageAlignment: imageAlignment,
            depthEffectColor: Color(hex: "#514964"),
            backgroundGradient: LinearGradient(
                colors: [
                    Color(hex: "#736595"),
                    Color(hex: "#736595")
                ],
                startPoint: .bottomLeading,
                endPoint: .topTrailing
            ),
            shouldFillHorizontalSpace: shouldFillHorizontalSpace,
            action: action
        )
    }
}

struct ActionButtonStyle: ButtonStyle {
    
    @SwiftUI.Environment(\.isEnabled) private var isEnabled
    
    let cornerRadius: CGFloat = 17
    let depthEffectColor: Color
    let backgroundGradient: LinearGradient
    var textShadow: Bool
    /// A flag used to fill the available horizontal space (centering the
    /// contents) or to fit the horizontal space to the contents of the action
    /// button.
    var shouldFillHorizontalSpace = false

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            ZStack {
                depthEffectColor
            }
            .cornerRadius(16)
            .offset(y: 1)

            // Text container
            configuration.label
                .foregroundColor(.white)
                .font(.body)
                .padding(.vertical, 8)
                .padding(.horizontal, 13)
                .shadow(
                    color: textShadow ? Color(white: 0, opacity: 0.15) : .clear,
                    radius: 2,
                    x: 0,
                    y: 2
                )
                .opacity(isEnabled ? 1 : 0.5)
                .background(
                    ZStack {
                        LinearGradient(
                            colors: [
                                Color(red: 1, green: 1, blue: 1, opacity: 0.2),
                                Color(red: 1, green: 1, blue: 1, opacity: 1.0),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .blendMode(.softLight)
                        
                        backgroundGradient.blendMode(.normal)
                    }
                )
                .cornerRadius(cornerRadius)
                .offset(y: configuration.isPressed ? 2 : 0)
        }
        .fixedSize(horizontal: !shouldFillHorizontalSpace, vertical: true)
    }
}

struct ActionButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ActionButton(title: .localizable.done, action: {})

            ActionButton(title: .localizable.done, action: {})
                .disabled(true)
            
            ActionButton(
                title: .localizable.edit,
                font: .clarity(.medium),
                image: Image.editProfile, 
                textColor: Color(hex: "#f26141"),
                depthEffectColor: Color(hex: "#f8d4b6"),
                backgroundGradient: LinearGradient(
                    colors: [Color(hex: "#FFF8F7"), Color(hex: "#FDF6F5")],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                textShadow: false,
                action: {}
            )
            
            SecondaryActionButton(title: .localizable.edit, action: {})

            // Something that should wrap at larger text sizes
            SecondaryActionButton(title: .localizable.reportSendToNosConfirmation("harassment"), action: {})
        }
    }
}
