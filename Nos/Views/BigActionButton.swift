//
//  BigGradientButton.swift
//  Planetary-scuttle
//
//  Created by Matthew Lorentz on 1/17/23.
//  Copyright © 2023 Verse Communications Inc. All rights reserved.
//

import SwiftUI

/// A big bright button that is used as the primary call-to-action on a screen.
struct BigActionButton: View {
    
    var title: LocalizedStringResource
    var backgroundGradient = LinearGradient(
        colors: [
            Color(hex: "#F06337"),
            Color(hex: "#F24E55")
        ],
        startPoint: .top,
        endPoint: .bottom
    )
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
            PlainText(title)
                .font(.clarityBold)
                .transition(.opacity)
                .font(.headline)
        })
        .lineLimit(nil)
        .foregroundColor(.black)
        .buttonStyle(BigActionButtonStyle(backgroundGradient: backgroundGradient))
        .disabled(disabled)
    }
}

struct BigActionButtonStyle: ButtonStyle {
    
    @SwiftUI.Environment(\.isEnabled) private var isEnabled
    
    var backgroundGradient: LinearGradient
    let cornerRadius: CGFloat = 50
    
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            // Button shadow/background
            ZStack {
                Color(hex: "#C13036")
            }
            .cornerRadius(80)
            .offset(y: 4.5)
            .shadow(
                color: Color(white: 0, opacity: 0.2), 
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
                            Gradient.Stop(color: Color(red: 0.94, green: 0.39, blue: 0.22), location: 0.00),
                            Gradient.Stop(color: Color(red: 0.95, green: 0.3, blue: 0.33), location: 1.00),
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
                    .font(.headline)
                    .padding(15)
                    .shadow(
                        color: Color(white: 0, opacity: 0.15),
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
