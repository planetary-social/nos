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
    var font: Font = .clarity
    var image: Image?
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
    var textShadow = true
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
            HStack {
                image
                PlainText(title.string)
                    .font(font)
                    .transition(.opacity)
                    .font(.headline)
                    .foregroundColor(textColor)
            }
        })
        .lineLimit(nil)
        .foregroundColor(.black)
        .buttonStyle(ActionButtonStyle(
            textShadow: textShadow, borderColor: depthEffectColor
        ))
        .disabled(disabled)
    }
}

// TODO:    The coloring of these butttons need to not be hard coded
//          so that they're displayed correctly in both light and dark mode.

struct SecondaryActionButton: View {
    var title: Localized
    var action: () async -> Void
    
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
    var textShadow: Bool
    var borderColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            ZStack {
                Color.clear
            }
            .cornerRadius(cornerRadius)
            .overlay(RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(borderColor, lineWidth: 2))

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
            
            ActionButton(
                title: Localized.edit, 
                font: .clarityMedium,
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
            
            SecondaryActionButton(title: Localized.edit, action: {})
            
            // Something that should wrap at larger text sizes
            SecondaryActionButton(title: Localized.reportConfirmation, action: {})
        }
    }
}
