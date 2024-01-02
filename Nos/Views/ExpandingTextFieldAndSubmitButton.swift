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

    var placeholder: LocalizedStringResource
    @Binding var reply: EditableNoteText
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
                            reply = EditableNoteText()
                            disabled = false
                        }
                    },
                    label: {
                        Text(.localizable.post)
                    }
                )
                .disabled(disabled)
            }
        }
        .onChange(of: reply) { _, newText in
            showPostButton = !newText.isEmpty || focus.wrappedValue
        }
        .onChange(of: focus.wrappedValue) { _, bool in
            showPostButton = !reply.isEmpty || bool
        }
        .padding(8)
    }
}

struct ExpandingTextFieldAndSubmitButton_Previews: PreviewProvider {

    @State static var reply = EditableNoteText(string: "Hello World")
    @FocusState static var isFocused: Bool

    static var previews: some View {
        VStack {
            Spacer()
            VStack {
                HStack(spacing: 10) {
                    ExpandingTextFieldAndSubmitButton(
                        placeholder: .reply.postAReply,
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
