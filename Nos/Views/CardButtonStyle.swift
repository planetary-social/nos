import SwiftUI

struct CardButtonStyle: ButtonStyle {
    
    var style: CardStyle

    func makeBody(configuration: Configuration) -> some View {
        configuration.label.mimicCardButtonStyle(style: style, isPressed: configuration.isPressed)
    }
}

fileprivate extension CardStyle {
    var cornerRadius: CGFloat {
        switch self {
        case .golden:
            return 16
        case .compact:
            return 21
        }
    }
}

extension View {
    func mimicCardButtonStyle(style: CardStyle = .compact, isPressed: Bool = false) -> some View {
        self
            .offset(y: isPressed ? 3 : 0)
            .background(
                Color.card3d
                    .cornerRadius(style.cornerRadius)
                    .offset(y: 4.5)
                    .shadow(
                        color: Color.cardShadowBottom,
                        radius: isPressed ? 2 : 5,
                        x: 0,
                        y: isPressed ? 1 : 4
                    )
            )
    }
}

#Preview {
    VStack {
        Spacer()
        Button {
        } label: { 
            VStack {
                Text("hello world")
                    .padding()
            }
            .background(Color.cardBgTop.cornerRadius(18))
        }
        .buttonStyle(CardButtonStyle(style: .compact))
        Spacer()
    }
}
