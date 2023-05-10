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
    var focus: FocusState<Bool>.Binding
    var action: () async -> Void
    
    @State private var showPostButton = false
    @State var disabled = false
    
    var body: some View {
        HStack {
            TextEditor(text: $reply)
                .placeholder(when: reply.isEmpty, placeholder: {
                    VStack {
                        Text(placeholder)
                            .foregroundColor(.secondaryTxt)
                            .padding(.top, 10)
                            .padding(.leading, 7.5)
                        Spacer()
                    }
                })
                .scrollContentBackground(.hidden)
                .padding(.leading, 6)
                .background(Color.appBg)
                .cornerRadius(17.5)
                .frame(maxHeight: 270)
                .focused(focus)
            
            if showPostButton {
                Button(
                    action: {
                        disabled = true
                        focus.wrappedValue = false
                        Task {
                            await action()
                            reply = ""
                            disabled = false
                        }
                    },
                    label: {
                        Localized.post.view
                    }
                )
                .disabled(disabled)
            }
        }
        .onChange(of: focus.wrappedValue) { bool in
            showPostButton = bool
        }
        .padding(8)
    }
}
