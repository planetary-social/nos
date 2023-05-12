//
//  ExpandingTextFieldAndSubmitButton.swift
//  Nos
//
//  Created by Jason Cheatham on 3/2/23.
//

import Foundation
import SwiftUI

struct ExpandingTextFieldAndSubmitButton: View {

    @Environment(\.managedObjectContext) private var viewContext

    var placeholder: String
    @Binding var reply: AttributedString
    var focus: FocusState<Bool>.Binding
    var action: () async -> Void
    
    @State private var showPostButton = false
    @State var disabled = false
    
    var body: some View {
        HStack {
            EditableText($reply, guid: UUID())
                .placeholder(when: reply.characters.isEmpty, placeholder: {
                    VStack {
                        Text(placeholder)
                            .foregroundColor(.secondaryText)
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

struct ExpandingTextFieldAndSubmitButton_Previews: PreviewProvider {
    @State static var reply = AttributedString("kahj bflkasbhd lkasjdh lkasjdh lkasjdh laksjdh laksjdh kahj bflkasbhd lkasjdh lkasjdh lkasjdh laksjdh laksjdh kahj bflkasbhd lkasjdh lkasjdh lkasjdh laksjdh laksjdh kahj bflkasbhd lkasjdh lkasjdh lkasjdh laksjdh laksjdh a")

    static var previews: some View {
        VStack {
            Spacer()
            VStack {
                HStack(spacing: 10) {
                    ExpandingTextFieldAndSubmitButton(placeholder: "Write something", reply: $reply) {

                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}
