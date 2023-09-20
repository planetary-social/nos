//
//  CardButtonStyle.swift
//  Nos
//
//  Created by Jason Cheatham on 2/16/23.
//

import SwiftUI

struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .shadow(
                color: .cardShadowBottom,
                radius: configuration.isPressed ? 2 : 5,
                x: 0,
                y: configuration.isPressed ? 1 : 4
            )
            .offset(y: configuration.isPressed ? 3 : 0)
    }
}
