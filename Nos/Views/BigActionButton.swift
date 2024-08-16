import SwiftUI

/// A big bright button that is used as the primary call-to-action on a screen.
struct BigActionButton: View {
    
    var title: LocalizedStringResource
    var backgroundGradient: LinearGradient = .bigAction
    var action: () async -> Void
    @State var disabled = false
    
    var body: some View {
        Button(action: {
            disabled = true
            Task {
                await action()
                disabled = false
            }
        }, label: {
            Text(title)
                .font(.clarity(.bold))
                .transition(.opacity)
                .font(.headline)
        })
        .lineLimit(nil)
        .foregroundColor(.black)
        .buttonStyle(BigActionButtonStyle(backgroundGradient: backgroundGradient))
        .disabled(disabled)
    }
}

extension LinearGradient {
    static var bigAction: LinearGradient {
        LinearGradient(
            colors: [
                Color.bigActionButtonGradientTop,
                Color.bigActionButtonGradientBottom
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

struct BigActionButtonStyle: ButtonStyle {
    
    @SwiftUI.Environment(\.isEnabled) private var isEnabled
    
    var backgroundGradient: LinearGradient = .bigAction
    let cornerRadius: CGFloat = 50
    
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            // Button shadow/background
            ZStack {
                Color.bigActionButtonBackground
            }
            .cornerRadius(80)
            .offset(y: 4.5)
            .shadow(
                color: Color.lightShadow,
                radius: 2,
                x: 0, 
                y: configuration.isPressed ? 0 : 1
            )
            
            // Button face
            ZStack {
                // Gradient background color
                ZStack {
                    LinearGradient(
                        stops: [
                            Gradient.Stop(color: Color.bigActionButtonLinearGradientStop1, location: 0.00),
                            Gradient.Stop(color: Color.bigActionButtonLinearGradientStop2, location: 1.00),
                        ],
                        startPoint: UnitPoint(x: 0.5, y: 0),
                        endPoint: UnitPoint(x: 0.5, y: 0.99)
                    )
                    .blendMode(.softLight)
                    
                    backgroundGradient.blendMode(.normal)
                }
                
                // Text container
                configuration.label
                    .foregroundColor(.white)
                    .font(.clarity(.bold, textStyle: .title3))
                    .padding(15)
                    .shadow(
                        color: Color.bigActionButtonLabelShadow,
                        radius: 2,
                        x: 0,
                        y: 2
                    )
                    .opacity(isEnabled ? 1 : 0.5)
            }
            .cornerRadius(cornerRadius)
            .offset(y: configuration.isPressed ? 3 : 0)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct BigGradientButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            BigActionButton(title: .localizable.tryIt, action: {})
                .frame(width: 268)
            
            BigActionButton(title: .localizable.tryIt, action: {})
                .disabled(true)
                .frame(width: 268)
        }
    }
}
