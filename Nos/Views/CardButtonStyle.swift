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
        ZStack {
            ZStack {
                Color.card3d
            }
            .cornerRadius(20)
            .offset(y: 4.5)
            .shadow(
                color: .cardShadowBottom,
                radius: configuration.isPressed ? 2 : 5,
                x: 0,
                y: configuration.isPressed ? 1 : 4
            )
            configuration.label
                .offset(y: configuration.isPressed ? 3 : 0)
        }
    }
}

extension View {

    func mimicCardButtonStyle() -> some View {
        ZStack {
            ZStack {
                Color.card3d
            }
            .cornerRadius(20)
            .offset(y: 4.5)
            .shadow(
                color: .cardShadowBottom,
                radius: 5,
                x: 0,
                y: 4
            )
            self
                .offset(y: 0)
        }
    }
}
