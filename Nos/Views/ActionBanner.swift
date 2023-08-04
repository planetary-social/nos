//
//  ActionBanner.swift
//  Nos
//
//  Created by Matthew Lorentz on 8/1/23.
//

import SwiftUI

/// A large colorful banner with a message and action button.
struct ActionBanner: View {
    
    var messageText: Localized
    var buttonText: Localized
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
                .cornerRadius(11)
                .offset(y: 2)
            
            VStack {
                HStack {
                    messageText.view
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
            .cornerRadius(9)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct ActionBanner_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ActionBanner(
                messageText: .completeProfileMessage, 
                buttonText: .completeProfileButton
            ) {}
                .padding(20)
        }
        .background(Color.appBg)
    }
}
