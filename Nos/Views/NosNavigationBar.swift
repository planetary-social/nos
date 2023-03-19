//
//  NosNavigationBar.swift
//  Nos
//
//  Created by Matthew Lorentz on 3/18/23.
//

import SwiftUI

struct NosNavigationBarModifier: ViewModifier {
    
    var title: Localized
    
    func body(content: Content) -> some View {
        content
            .navigationBarTitle(title.string, displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    PlainText(title.string)
                        .font(.clarityTitle3)
                        .foregroundColor(.primaryTxt)
                        .padding(.leading, 14)
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.cardBgBottom, for: .navigationBar)
    }
}

extension View {
    func nosNavigationBar(title: Localized) -> some View {
        self.modifier(NosNavigationBarModifier(title: title))
    }
}

struct NosNavigationBar_Previews: PreviewProvider {
    
    static var previews: some View {
        NavigationStack {
            VStack {
                Spacer()
                Text("Content")
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(Color.appBg)
            .nosNavigationBar(title: .homeFeed)
        }
    }
}
