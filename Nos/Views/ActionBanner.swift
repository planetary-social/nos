//
//  ActionBanner.swift
//  Nos
//
//  Created by Matthew Lorentz on 8/1/23.
//

import SwiftUI

struct ActionBanner: View {
    
    var messageText: Localized
    var buttonText: Localized
    var action: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                messageText.view
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                    .padding(.leading, 4)
                    .foregroundColor(.white)
                    .bold()
                    .shadow(radius: 2)
                Spacer()
            }
            
            HStack {
                ActionButton(
                    title: buttonText,
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
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(
            HStack {
                Spacer()
                Image(systemName: "checkmark.seal.fill")
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .foregroundColor(Color(hex: "#F95795"))
            }
                .offset(x: 28)
        )
        .listRowBackground(
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "#F08508"), Color(hex: "#F43F75")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        )
    }
}

struct ActionBanner_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            ActionBanner(
                messageText: .unsTagline, 
                buttonText: .setUpUniversalName
            ) {}
        }
        .background(Color.appBg)
    }
}
