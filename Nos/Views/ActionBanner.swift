//
//  ActionBanner.swift
//  Nos
//
//  Created by Matthew Lorentz on 8/1/23.
//

import SwiftUI

/// A large colorful banner with a message and action button.
struct ActionBanner: View {
    
    var messageText: LocalizedStringResource
    var buttonText: LocalizedStringResource
    var buttonImage: Image?
    var inForm = false
    var action: () -> Void
    
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "#F08508"), Color(hex: "#F43F75")],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    var body: some View {
        ZStack {
            Color(hex: "#923c2c")
                .cornerRadius(21)
                .offset(y: 2)
            
            VStack {
                HStack {
                    Text(messageText)
                        .padding(.top, 8)
                        .padding(.bottom, 12)
                        .foregroundColor(.white)
                        .lineSpacing(6)
                        .bold()
                        .shadow(radius: 2)
                    Spacer()
                }
                
                HStack {
                    ActionButton(
                        title: buttonText,
                        font: .clarityMedium,
                        image: Image.editProfile,
                        textColor: Color(hex: "#f26141"),
                        depthEffectColor: Color(hex: "#f8d4b6"),
                        backgroundGradient: LinearGradient(
                            colors: [Color(hex: "#FFF8F7"), Color(hex: "#FDF6F5")],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        textShadow: false
                    ) {
                        action()
                    }
                    .frame(minHeight: 40)
                    Spacer()
                }
            }
            .padding(.vertical, inForm ? 12 : 24)
            .padding(.horizontal, inForm ? 4 : 24)
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
                    .offset(y: -2)
            )
            .cornerRadius(20)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct ActionBanner_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ActionBanner(
                messageText: .localizable.completeProfileMessage,
                buttonText: .localizable.completeProfileButton
            ) {}
                .padding(20)
        }
        .background(Color.appBg)
    }
}
