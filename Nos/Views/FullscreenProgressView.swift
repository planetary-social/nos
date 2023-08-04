//
//  FullscreenProgressView.swift
//  Nos
//
//  Created by Matthew Lorentz on 4/19/23.
//

import SwiftUI
import SwiftUINavigation

struct FullscreenProgressView: View {
    
    @Binding var isPresented: Bool 

    var text: String?
    var hideAfter: DispatchTime?
    
    var body: some View {
        VStack {
            Spacer()
            ProgressView()
                .foregroundColor(.primaryTxt)
            if let text {
                Text(text).padding(10)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.appBg)
        .onAppear {
            if let hideAfter {
                DispatchQueue.main.asyncAfter(deadline: hideAfter) {
                    isPresented = false
                }
            }
        }
    }
}

struct FullscreenProgressView_Previews: PreviewProvider {
    static var previews: some View {
        FullscreenProgressView(isPresented: .constant(true), text: nil)
    }
}
