//
//  ExpandingTextFieldAndSubmitButton.swift
//  Nos
//
//  Created by Jason Cheatham on 3/2/23.
//

import Foundation
import SwiftUI

struct ExpandingTextFieldAndSubmitButton: View {
    var placeholder: String
    @Binding var reply: String
    var action: () -> Void
    
    var body: some View {
        ZStack(alignment: .trailing) {
            TextField(placeholder, text: $reply, axis: .vertical)
                .lineLimit(5)
                .textFieldStyle(.roundedBorder)
                .padding(.trailing, 30)
            Button(
                action: {
                    self.action()
                    reply = ""
                },
                label: {
                    Image(systemName: "paperplane.fill")
                        .font(.headline)
                }
            )
        }
        .padding(.trailing, 8)
        .opacity(1.0)
    }
}
