//
//  FullscreenProgressView.swift
//  Nos
//
//  Created by Matthew Lorentz on 4/19/23.
//

import SwiftUI

struct FullscreenProgressView: View {
    
    @Binding var isPresented: Bool 
    
    var hideAfter: DispatchTime?
    
    var body: some View {
        VStack {
            Spacer()
            ProgressView()
                .foregroundColor(.primaryTxt)
                .scaleEffect(2)
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
        FullscreenProgressView(isPresented: .constant(true))
    }
}
