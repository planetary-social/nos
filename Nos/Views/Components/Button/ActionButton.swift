import SwiftUI

/// A big bright button that is used as the primary call-to-action on a screen.
struct ActionButton: View {
    
    enum ImageAlignment {
        case left
        case right
    }

    let titleText: Text
    var font: Font = .clarity(.bold)
    var image: Image?
    var imageAlignment: ImageAlignment = .left
    var padding = EdgeInsets(top: 8, leading: 13, bottom: 8, trailing: 13)
    var textColor = Color.white
    var depthEffectColor = Color.actionPrimaryDepthEffect
    var backgroundGradient = LinearGradient.diagonalAccent2
    var textShadow = true
    /// A flag used to fill the available horizontal space (centering the
    /// contents) or to fit the horizontal space to the contents of the action
    /// button.
    var shouldFillHorizontalSpace = false
    var action: (() async -> Void)?
    @State var disabled = false
    
    init(
        title: String,
        font: Font = .clarity(.bold),
        image: Image? = nil,
        imageAlignment: ImageAlignment = .left,
        padding: EdgeInsets = EdgeInsets(top: 8, leading: 13, bottom: 8, trailing: 13),
        textColor: SwiftUI.Color = Color.white,
        depthEffectColor: Color = Color.actionPrimaryDepthEffect,
        backgroundGradient: LinearGradient = LinearGradient.diagonalAccent2,
        textShadow: Bool = true,
        shouldFillHorizontalSpace: Bool = false,
        action: (() async -> Void)? = nil,
        disabled: Bool = false
    ) {
        self.titleText = Text(title)
        self.font = font
        self.image = image
        self.imageAlignment = imageAlignment
        self.padding = padding
        self.textColor = textColor
        self.depthEffectColor = depthEffectColor
        self.backgroundGradient = backgroundGradient
        self.textShadow = textShadow
        self.shouldFillHorizontalSpace = shouldFillHorizontalSpace
        self.action = action
        self.disabled = disabled
    }
    
    init(
        _ titleKey: LocalizedStringKey,
        font: Font = .clarity(.bold),
        image: Image? = nil,
        imageAlignment: ImageAlignment = .left,
        padding: EdgeInsets = EdgeInsets(top: 8, leading: 13, bottom: 8, trailing: 13),
        textColor: Color = Color.white,
        depthEffectColor: Color = Color.actionPrimaryDepthEffect,
        backgroundGradient: LinearGradient = LinearGradient.diagonalAccent2,
        textShadow: Bool = true,
        shouldFillHorizontalSpace: Bool = false,
        action: (() async -> Void)? = nil,
        disabled: Bool = false
    ) {
        self.titleText = Text(titleKey)
        self.font = font
        self.image = image
        self.imageAlignment = imageAlignment
        self.padding = padding
        self.textColor = textColor
        self.depthEffectColor = depthEffectColor
        self.backgroundGradient = backgroundGradient
        self.textShadow = textShadow
        self.shouldFillHorizontalSpace = shouldFillHorizontalSpace
        self.action = action
        self.disabled = disabled
    }
    
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
                titleText
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
            padding: padding,
            textShadow: textShadow,
            shouldFillHorizontalSpace: shouldFillHorizontalSpace
        ))
        .disabled(disabled)
    }
}

struct SecondaryActionButton: View {
    
    private let button: ActionButton
    
    /// Initializes a ``SecondaryActionButton``.
    /// - Parameters:
    ///   - title: The title for the button.
    ///   - font: The font to use.
    ///   - image: An image for the button. Optional.
    ///   - imageAlignment: The side of the button the image should appear on.
    ///   - shouldFillHorizontalSpace: A flag used to fill the available horizontal space (centering the
    /// contents) or to fit the horizontal space to the contents of the action
    /// button.
    ///   - action: The action to perform when the button is tapped.
    init(
        title: String,
        font: Font = .clarity(.bold),
        image: Image? = nil,
        imageAlignment: ActionButton.ImageAlignment = .left,
        shouldFillHorizontalSpace: Bool = false,
        action: (() -> Void)? = nil
    ) {
        button = ActionButton(
            title: title,
            font: font,
            image: image,
            imageAlignment: imageAlignment,
            depthEffectColor: .actionSecondaryDepthEffect,
            backgroundGradient: .verticalAccentSecondary,
            shouldFillHorizontalSpace: shouldFillHorizontalSpace,
            action: action
        )
    }
    
    init(
        _ titleKey: LocalizedStringKey,
        font: Font = .clarity(.bold),
        image: Image? = nil,
        imageAlignment: ActionButton.ImageAlignment = .left,
        shouldFillHorizontalSpace: Bool = false,
        action: (() async -> Void)? = nil
    ) {
        button = ActionButton(
            titleKey,
            font: font,
            image: image,
            imageAlignment: imageAlignment,
            depthEffectColor: .actionSecondaryDepthEffect,
            backgroundGradient: .verticalAccentSecondary,
            shouldFillHorizontalSpace: shouldFillHorizontalSpace,
            action: action
        )
    }
    
    var body: some View {
        button
    }
}

struct ActionButtonStyle: ButtonStyle {
    
    @Environment(\.isEnabled) private var isEnabled
    
    let cornerRadius: CGFloat = 17
    let depthEffectColor: Color
    let backgroundGradient: LinearGradient
    let padding: EdgeInsets
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
                .padding(padding)
                .shadow(
                    color: textShadow ? Color.actionButtonTextShadow : .clear,
                    radius: 2,
                    x: 0,
                    y: 2
                )
                .opacity(isEnabled ? 1 : 0.4)
                .background(
                    ZStack {
                        LinearGradient(
                            colors: [
                                Color.actionButtonBackgroundGradientTop,
                                Color.actionButtonBackgroundGradientBottom
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
            ActionButton("done")

            ActionButton("done")
                .disabled(true)
            
            ActionButton(
                "edit",
                font: .clarity(.medium),
                image: Image.editProfile, 
                textColor: Color.actionBannerButtonTxt,
                depthEffectColor: Color.actionBannerButtonEffect,
                backgroundGradient: LinearGradient(
                    colors: [
                        Color.actionBannerButtonGradientLeading,
                        Color.actionBannerButtonGradientTrailing
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                textShadow: false
            )
            
            SecondaryActionButton("edit")

            // Something that should wrap at larger text sizes
            SecondaryActionButton(
                title: "The Nos moderation team will analyze the note for harassment content and may publish a report from our own account, concealing your identity."  // swiftlint:disable:this line_length
            )
            .disabled(true)
        }
    }
}
