//
//  ExpirationTimeButton.swift
//  Nos
//
//  Created by Matthew Lorentz on 5/5/23.
//

import SwiftUI

/// A button that lets the user select an `ExpirationTimeOption` to specify when an event should be deleted.
struct ExpirationTimeButton: View {
    
    var model: ExpirationTimeOption
    @State var showClearButton = false
    var minSize: Binding<CGSize?>?
    @Binding var isSelected: Bool
    
    var body: some View {
        ZStack {
            let textLayer = HStack(spacing: 3) {
                HStack(spacing: 1) {
                    if showClearButton {
                        PlainText(Localized.noteDisappearsIn.string)
                            .foregroundColor(.secondaryText)
                            .font(.clarityCaption2)
                    }
                    
                    PlainText(model.unit)
                        .foregroundColor(.secondaryText)
                        .font(.clarityCaption2)
                }
                
                if showClearButton {
                    Image(systemName: "xmark")
                        .font(.callout)
                        .fontWeight(.heavy)
                        .foregroundColor(.secondaryAction)
                }
            }
            .padding(.horizontal, showClearButton ? 6 : 4)
            .padding(.vertical, 6)
            .frame(minWidth: minSize?.wrappedValue?.width, minHeight: minSize?.wrappedValue?.height)
            .cornerRadius(5)
            .background(Color.appBg)
            
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
                            .stroke(Color.buttonBevelBottom, lineWidth: 1)
                            .offset(x: 0, y: 0.8)
                            .padding(.horizontal, -0.8)
                            .clipped()
                    )
                    // top bevel
                    .overlay(
                        RoundedRectangle(cornerSize: CGSize(width: 5, height: 5))
                            .stroke(Color.buttonBevelTop, lineWidth: 1)
                            .offset(x: 0, y: -0.8)
                            .padding(.horizontal, -0.8)
                            .clipped()
                    )
            }
        }
        .accessibilityLabel(Text(model.accessibilityLabel))
        .cornerRadius(5)
        .onTapGesture {
            isSelected.toggle() 
        }
    }
}

//ExpirationTimeButton(model: ExpirationTimeOption.fifteenMins, isSelected: .constant(false))
//

struct ExpirationTimeButton_Previews: PreviewProvider {
    
    @State static var emptyExpirationTime: TimeInterval? 
    
    @State static var oneHourExpirationTime: TimeInterval? = 60 * 60
    
    static var previews: some View {
        VStack {
            HStack {
                ExpirationTimeButton(model: ExpirationTimeOption.oneHour, isSelected: .constant(false))
                ExpirationTimeButton(model: ExpirationTimeOption.sevenDays, showClearButton: true, isSelected: .constant(false))
                ExpirationTimeButton(model: ExpirationTimeOption.oneMonth, isSelected: .constant(false))
                ExpirationTimeButton(model: ExpirationTimeOption.oneYear, isSelected: .constant(true))
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(Color.appBg)
    }
}
