//
//  CardButtonStyle.swift
//  Nos
//
//  Created by Jason Cheatham on 2/16/23.
//

import SwiftUI

struct CardButtonStyle: ButtonStyle {
    
    var style: CardStyle
    
    @State private var configurationSize: CGSize = .zero
    
    var cornerRadius: CGFloat {
        switch style {
        case .golden:
            return 16
        case .compact:
            return 21
        }
    } 
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(y: configuration.isPressed ? 3 : 0)
            .background(
                Color.card3d
                    .cornerRadius(cornerRadius)
                    .offset(y: 4.5)
                    .shadow(
                        color: .cardShadowBottom,
                        radius: configuration.isPressed ? 2 : 5,
                        x: 0,
                        y: configuration.isPressed ? 1 : 4
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
