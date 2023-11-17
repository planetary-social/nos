//
//  ReplyButton.swift
//  Nos
//
//  Created by Martin Dutra on 20/10/23.
//

import SwiftUI

struct ReplyButton: View {
    var note: Event
    var replyAction: ((Event) -> Void)?

    @Environment(Router.self) private var router
    
    var body: some View {
        Button(action: {
            if let replyAction {
                replyAction(note)
            } else {
                router.push(ReplyToNavigationDestination(note: note))
            }
        }, label: {
            Image.buttonReply
                .padding(.leading, 10)
                .padding(.trailing, 23)
                .padding(.vertical, 12)
        })
    }
}
