//
//  ComposerActionBar.swift
//  Nos
//
//  Created by Matthew Lorentz on 5/3/23.
//

import SwiftUI

struct ComposerActionBar: View {
    
    @Binding var expirationTime: TimeInterval?
    
    enum SubMenu {
        case attachMedia
        case expirationDate
    }
    
    @State private var subMenu: SubMenu?
    
    var backArrow: some View {
        Button { 
            subMenu = .none
        } label: { 
            Image.backChevron
                .foregroundColor(.secondaryTxt)
                .frame(minWidth: 44, minHeight: 44)
        }
        .transition(.opacity)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            switch subMenu {
            case .none:
                // Attach Media
                Button { 
                    subMenu = .attachMedia
                } label: { 
                    Image.attachMediaButton
                        .foregroundColor(.secondaryTxt)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .padding(.leading, 8)
                .transition(.move(edge: .leading))
                .accessibilityLabel(Localized.attachMedia.view)
                
                // Expiration Time
                if let expirationTime, let option = ExpirationTimeOption(rawValue: expirationTime) {
                    ExpirationTimeButton(
                        model: option, 
                        showClearButton: true,
                        isSelected: Binding(get: { 
                            self.expirationTime == option.timeInterval
                        }, set: { 
                            self.expirationTime = $0 ? option.timeInterval : nil
                        })
                    )
                    .accessibilityLabel(Localized.expirationDate.view)
                    .padding(12)
                } else {
                    Button { 
                        subMenu = .expirationDate
                    } label: { 
                        Image.disappearingMessages
                            .foregroundColor(.secondaryTxt)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                }
                
            case .attachMedia:
                backArrow
                HighlightedText(
                    Localized.nostrBuildHelp.string,
                    highlightedWord: "nostr.build",
                    highlight: .diagonalAccent,
                    textColor: .primaryTxt,
                    font: .clarityCaption,
                    link: URL(string: "https://nostr.build")!
                )
                .transition(.move(edge: .trailing))
                .padding(10)
            case .expirationDate:
                backArrow
                ScrollView(.horizontal) {
                    HStack {
                        PlainText(Localized.noteDisappearsIn.string)
                            .font(.clarityCaption)
                            .foregroundColor(.primaryTxt)
                            .transition(.move(edge: .trailing))
                            .padding(10)
                        
                        ExpirationTimePicker(expirationTime: $expirationTime)
                            .padding(.vertical, 12)
                    }
                }
            }
            Spacer()
        }
        .animation(.easeInOut(duration: 0.2), value: subMenu)
        .transition(.move(edge: .leading))
        .onChange(of: expirationTime) { _ in
            subMenu = .none
        }
        .background(Color.actionBar)
    }
}

struct ComposerActionBar_Previews: PreviewProvider {
    
    @State static var emptyExpirationTime: TimeInterval? 
    @State static var setExpirationTime: TimeInterval? = 60 * 60
    
    static var previews: some View {
        VStack {
            Spacer()
            ComposerActionBar(expirationTime: $emptyExpirationTime)
            Spacer()
            ComposerActionBar(expirationTime: $setExpirationTime)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.appBg)
        .preferredColorScheme(.dark)
        .environment(\.sizeCategory, .extraExtraLarge)
    }
}
