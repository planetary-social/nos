//
//  NosForm.swift
//  Nos
//
//  Created by Matthew Lorentz on 9/27/23.
//

import SwiftUI
import SwiftUINavigation

struct NosForm<Content: View>: View {
    
    let content: Content
    
    init(@ViewBuilder builder: () -> Content) {
        self.content = builder()
    }
    
    var body: some View {
        VStack {
            ScrollView {
                content
                    .readabilityPadding()
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.appBg)
    }
}

struct NosForm_Previews: PreviewProvider {
    static var previews: some View {
        NosForm {
            NosFormSection(label: .profilePicture) {
                WithState(initialValue: "Alice") { text in
                    NosTextField(label: .url, text: text)
                }    
            }   
        }    
    }
}
