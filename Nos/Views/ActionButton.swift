//
//  BigGradientButton.swift
//  Planetary-scuttle
//
//  Created by Matthew Lorentz on 1/17/23.
//  Copyright © 2023 Verse Communications Inc. All rights reserved.
//

import SwiftUI

/// A big bright button that is used as the primary call-to-action on a screen.
struct ActionButton: View {
    
    var title: Localized
    var textColor = Color.white
    var depthEffectColor = Color(hex: "#A04651")
    var backgroundGradient = LinearGradient(
        colors: [
            Color(hex: "#F08508"),
            Color(hex: "#F43F75")
        ],
        startPoint: .bottomLeading,
        endPoint: .topTrailing
    )
    var textShadow: Bool = true
    var action: () -> Void
    
    var body: some View {
        Button(action: action, label: {
            PlainText(title.string)
                .font(.clarityBold)
                .transition(.opacity)
                .font(.headline)
                .foregroundColor(textColor)
        })
        .lineLimit(nil)
        .foregroundColor(.black)
        .buttonStyle(ActionButtonStyle(depthEffectColor: depthEffectColor, backgroundGradient: backgroundGradient, textShadow: textShadow))
    }
}

struct SecondaryActionButton: View {
    var title: Localized
    var action: () -> Void
    
    var body: some View {
        ActionButton(
            title: title,
            depthEffectColor: Color(hex: "#514964"),
            backgroundGradient: LinearGradient(
                colors: [
                    Color(hex: "#736595"),
                    Color(hex: "#736595")
                ],
                startPoint: .bottomLeading,
                endPoint: .topTrailing
            ),
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
                    }
                )
                .cornerRadius(cornerRadius)
                .offset(y: configuration.isPressed ? 2 : 0)
        }
        .fixedSize(horizontal: true, vertical: true)
    }
}

struct ActionButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ActionButton(title: Localized.done, action: {})
            
            ActionButton(title: Localized.done, action: {})
                .disabled(true)
            
            SecondaryActionButton(title: Localized.edit, action: {})
        }
    }
}
