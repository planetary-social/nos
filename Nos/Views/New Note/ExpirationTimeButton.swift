//
//  ExpirationTimeButton.swift
//  Nos
//
//  Created by Matthew Lorentz on 5/5/23.
//

import SwiftUI

struct ExpirationTimeButton: View {
    
    var model: ExpirationTimeOption
    @State var showClearButton = false
    var minSize: Binding<CGSize?>?
    @Binding var isSelected: Bool
    
    var body: some View {
        ZStack {
            let textLayer = HStack(spacing: 3) {
                VStack {
                    Text(model.topText)
                        .foregroundColor(.primaryTxt)
                    PlainText(model.unit)
                        .foregroundColor(.secondaryTxt)
                        .font(.clarityCaption2)
                }
                
                if showClearButton {
                    Image(systemName: "xmark")
                        .font(.callout)
                        .fontWeight(.heavy)
                        .foregroundColor(.secondaryTxt)
                }
            }
            .padding(.horizontal, showClearButton ? 6 : 4)
            .padding(.vertical, 6)
            .frame(minWidth: minSize?.wrappedValue?.width, minHeight: minSize?.wrappedValue?.height)
            .cornerRadius(5)
            .background(Color(hex: "#1C122E"))
            
            if isSelected {
                textLayer
                    // highlighted border
                    .overlay(
                        RoundedRectangle(cornerSize: CGSize(width: 5, height: 5))
                            .stroke(Color.accent, lineWidth: 1.2)
                    )
            } else {
                textLayer
                    // bottom bevel
                    .overlay(
                        RoundedRectangle(cornerSize: CGSize(width: 5, height: 5))
                            .stroke(Color(hex: "#140D21"), lineWidth: 1)
                            .offset(x: 0, y: 0.8)
                            .padding(.horizontal, -0.8)
                            .clipped()
                    )
                    // top bevel
                    .overlay(
                        RoundedRectangle(cornerSize: CGSize(width: 5, height: 5))
                            .stroke(Color(hex: "#362459"), lineWidth: 1)
                            .offset(x: 0, y: -0.8)
                            .padding(.horizontal, -0.8)
                            .clipped()
                    )
            }
        }
        .cornerRadius(5)
        .onTapGesture {
            isSelected.toggle() 
        }
    }
}

struct ExpirationTimeButton_Previews: PreviewProvider {
    
    @State static var emptyExpirationTime: TimeInterval? 
    
    @State static var oneHourExpirationTime: TimeInterval? = 60 * 60
    
    static var previews: some View {
        VStack {
            HStack {
                ExpirationTimeButton(model: ExpirationTimeOption.fifteenMins, isSelected: .constant(false))
                ExpirationTimeButton(model: ExpirationTimeOption.oneHour, isSelected: .constant(false))
                ExpirationTimeButton(model: ExpirationTimeOption.oneDay, isSelected: .constant(false))
                ExpirationTimeButton(model: ExpirationTimeOption.sevenDays, isSelected: .constant(true))
                ExpirationTimeButton(
                    model: ExpirationTimeOption.fifteenMins, 
                    showClearButton: true, 
                    isSelected: .constant(true)
                )
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(Color.appBg)
        .preferredColorScheme(.dark)
    }
}
