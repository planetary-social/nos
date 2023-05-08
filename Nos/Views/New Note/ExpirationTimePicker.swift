//
//  ExpirationTimePicker.swift
//  Nos
//
//  Created by Matthew Lorentz on 5/4/23.
//

import SwiftUI
import Foundation

struct ExpirationTimePicker: View {
    
    struct ExpirationTimeButtonSize: PreferenceKey {
        static let defaultValue: CGSize = .zero
        
        static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
            let next = nextValue()
            value = CGSize(
                width: max(value.width, next.width),
                height: max(value.height, next.height)
            )
        }
    }
    
    @Binding var expirationTime: TimeInterval?
    
    @State private var buttonSize: CGSize?
   
    var body: some View {
        HStack {
            ForEach(ExpirationTimeOption.allCases) { option in
                ExpirationTimeButton(
                    model: option, 
                    minSize: $buttonSize,
                    isSelected: Binding(get: { 
                        expirationTime == option.timeInterval
                    }, set: { 
                        expirationTime = $0 ? option.timeInterval : nil
                    })
                )
                .background(GeometryReader { geometry in
                    Color.clear.preference(
                        key: ExpirationTimeButtonSize.self,
                        value: geometry.size
                    )
                })
            }
        }
        .onPreferenceChange(ExpirationTimeButtonSize.self) {
            buttonSize = $0
        }
    }
}

struct ExpirationTimePicker_Previews: PreviewProvider {
    
    @State static var emptyExpirationTime: TimeInterval? 
    
    @State static var oneHourExpirationTime: TimeInterval? = 60 * 60
    
    static var previews: some View {
        VStack {
            ExpirationTimePicker(expirationTime: $emptyExpirationTime)
                .padding(10)
            ExpirationTimePicker(expirationTime: $oneHourExpirationTime)
                .padding(10)
        }
        .frame(maxWidth: .infinity)
        .background(Color.appBg)
        .preferredColorScheme(.dark)
    }
}
