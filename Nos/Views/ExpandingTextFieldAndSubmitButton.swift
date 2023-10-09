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

    var placeholder: Localizable // Ensure 'Localizable' is defined elsewhere
    @Binding var reply: EditableNoteText // Ensure 'EditableNoteText' is defined elsewhere
    @FocusState var isFocused: Bool
    var action: () async -> Void
    
    @State private var showPostButton = false
    @State var disabled = false

    @State private var calculatedHeight: CGFloat = 44
    
    var body: some View {
        HStack {
            NoteTextEditor(text: $reply, placeholder: placeholder, focus: $isFocused)
                .frame(maxHeight: 270)
                .background(Color.appBg)
                .cornerRadius(17.5)
            if showPostButton {
                Button(
                    action: {
                        disabled = true
                        isFocused = false
                        Task {
                            await action()
                            reply = EditableNoteText() // Ensure appropriate initialization
                            disabled = false
                        }
                    },
                    label: {
                        Localized.post.view // Ensure 'Localized' is defined elsewhere
                    }
                )
                .disabled(disabled)
            }
        }
        .onChange(of: reply) { newText in
            // If newText is not empty or if the editor is focused, show the post button
            showPostButton = !newText.isEmpty || isFocused
        }
        .onChange(of: isFocused) { focused in
            // Update the post button visibility based on focus state
            showPostButton = focused
        }
        .padding(8)
    }
}

// Your previews code
struct ExpandingTextFieldAndSubmitButton_Previews: PreviewProvider {

    @State static var reply = EditableNoteText(string: "Hello World")
    @FocusState static var isFocused: Bool

    static var previews: some View {
        VStack {
            Spacer()
            VStack {
                HStack(spacing: 10) {
                    ExpandingTextFieldAndSubmitButton(
                        placeholder: Localized.Reply.postAReply,
                        reply: $reply,
                        action: {}
                    )
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}
