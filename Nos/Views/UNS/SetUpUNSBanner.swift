//
//  SetUpUNSBanner.swift
//  Nos
//
//  Created by Matthew Lorentz on 6/9/23.
//

import SwiftUI

struct SetUpUNSBanner: View {
    
    var action: () -> Void
    
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [.unsGradientLeading, .unsGradientTrailing],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    var body: some View {
        ZStack {
            Color.unsBackground
                .cornerRadius(21)
                .offset(y: 2)
            VStack {
                HStack {
                    Text(.localizable.unsTagline)
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
                        title: .localizable.manageUniversalName,
                        textColor: .unsButtonText,
                        depthEffectColor: .unsButtonEffect,
                        backgroundGradient: LinearGradient(
                            colors: [.unsButtonGradientLeading, .unsButtonGradientTrailing],
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
            .padding(.vertical, 24)
            .padding(.horizontal, 24)
            .background(
                HStack {
                    Spacer()
                    Image(systemName: "checkmark.seal.fill")
                        .resizable()
                        .aspectRatio(1, contentMode: .fit)
                        .foregroundColor(.unsCheckmark)
                }
                    .offset(x: 28)
            )
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

struct SetUpUNSBanner_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            SetUpUNSBanner {}
                .padding(20)
        }
        .background(Color.appBg)
    }
}
