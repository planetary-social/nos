//
//  CardButtonStyle.swift
//  Nos
//
//  Created by Jason Cheatham on 2/16/23.
//

import SwiftUI

struct CardButtonStyle: ButtonStyle {
    
    var style: CardStyle
    
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
            .mimicCardButtonStyle(isPressed: configuration.isPressed)
    }
}

extension View {

    func mimicCardButtonStyle(isPressed: Bool = false) -> some View {
        ZStack {
            ZStack {
                Color.card3d
            }
            .cornerRadius(20)
            .offset(y: 4.5)
            .shadow(
                color: .cardShadowBottom,
                radius: isPressed ? 2 : 5,
                x: 0,
                y: isPressed ? 1 : 4
            )
            self
                .offset(y: isPressed ? 3 : 0)
        }
    }
}
