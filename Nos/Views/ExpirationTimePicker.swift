//
//  ExpirationTimePicker.swift
//  Nos
//
//  Created by Matthew Lorentz on 5/4/23.
//

import SwiftUI
import Foundation

enum ExpirationTimeOption: Double, Identifiable, CaseIterable {
    
    // Raw value is the number of seconds until this message expires
    case fifteenMins = 900
    case oneHour = 3600
    case oneDay = 86_400
    case sevenDays = 604_800
    
    var id: TimeInterval {
        rawValue
    }
    
    var topText: String {
        switch self {
        case .fifteenMins:
            return "15"
        case .oneHour:
            return "1"
        case .oneDay:
            return "24"
        case .sevenDays:
            return "7"
        }
    }
    
    var unit: String {
        switch self {
        case .fifteenMins:
            return "min"
        case .oneHour:
            return "hour"
        case .oneDay:
            return "hours"
        case .sevenDays:
            return "days"
        }
    }
    
    var timeInterval: TimeInterval {
        rawValue
    }
}

struct ExpirationTimePicker: View {
    
    struct ExpirationTimeButtonSize: PreferenceKey {
        static let defaultValue: CGSize = .zero
        
        static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
            value = CGSize(
                width: max(value.width, nextValue().width),
                height: max(value.height, nextValue().height)
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
                .frame(width: buttonSize?.width, height: buttonSize?.height)
            }
        }
        .onPreferenceChange(ExpirationTimeButtonSize.self) {
            buttonSize = $0
        }
    }
}

struct ExpirationTimeButton: View {
    
    var model: ExpirationTimeOption
    @Binding var isSelected: Bool
    
    var body: some View {
        ZStack {
            let textLayer = VStack {
                Text(model.topText)
                    .foregroundColor(.primaryTxt)
                PlainText(model.unit)
                    .foregroundColor(.secondaryTxt)
                    .font(.clarityCaption2)
            }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
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
