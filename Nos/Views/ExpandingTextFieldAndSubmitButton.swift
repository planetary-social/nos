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

    var placeholder: any Localizable
    @Binding var reply: NSAttributedString
    var focus: FocusState<Bool>.Binding
    var action: () async -> Void
    
    @State private var showPostButton = false
    @State var disabled = false

    @State private var calculatedHeight: CGFloat = 44
    
    var body: some View {
        HStack {
            NoteTextEditor(text: $reply, placeholder: placeholder, focus: focus)
                .frame(maxHeight: 270)
                .background(Color.appBg)
                .cornerRadius(17.5)
            if showPostButton {
                Button(
                    action: {
                        disabled = true
                        focus.wrappedValue = false
                        Task {
                            await action()
                            reply = NSAttributedString("")
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

    @State static var reply = NSAttributedString("Hello World")
    @FocusState static var isFocused: Bool

    static var previews: some View {
        VStack {
            Spacer()
            VStack {
                HStack(spacing: 10) {
                    ExpandingTextFieldAndSubmitButton(
                        placeholder: Localized.Reply.postAReply, 
                        reply: $reply, 
                        focus: $isFocused,
                        action: {}
                    )
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}
