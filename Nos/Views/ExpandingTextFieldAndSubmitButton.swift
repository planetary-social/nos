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
    var action: () async -> Void
    
    @FocusState private var textEditorInFocus
    @State private var showPostButton = false
    @State var disabled = false
    
    var body: some View {
        HStack {
            TextEditor(text: $reply)
                .placeholder(when: reply.isEmpty, placeholder: {
                    VStack {
                        Text(placeholder)
                            .foregroundColor(.secondaryTxt)
                            .padding(.top, 9.5)
                            .padding(.leading, 7.5)
                        Spacer()
                    }
                })
                .scrollContentBackground(.hidden)
                .padding(.leading, 6)
                .background(Color.appBg)
                .cornerRadius(17.5)
                .frame(maxHeight: 270)
                .focused($textEditorInFocus)
            
            if showPostButton {
                Button(
                    action: {
                        disabled = true
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
                .transition(.move(edge: .trailing))
            }
        }
        .onChange(of: textEditorInFocus) { bool in
            withAnimation(.spring(response: 0.2)) {
                showPostButton = bool
            }
        }
        .padding(8)
    }
}
