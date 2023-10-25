//
//  ThreadRootView.swift
//  Nos - This is the root note card for threads.
//
//  Created by Rabble on 10/16/23.
//

import SwiftUI

struct ThreadRootView<Reply: View>: View {
    var root: Event
    var tapAction: ((Event) -> Void)?
    var reply: Reply
    
    var thread: [Event] = []
    
    @EnvironmentObject private var router: Router
    
    init(root: Event, tapAction: ((Event) -> Void)?, @ViewBuilder reply: () -> Reply) {
        self.root = root
        self.tapAction = tapAction
        self.reply = reply()
    }
    
    var body: some View {
        ZStack {
            VStack {
                NoteButton(note: root, hideOutOfNetwork: false, tapAction: tapAction)
                    .scaleEffect(0.9) // Make the button 80% of its original size.
                    .frame(maxHeight: 500, alignment: .top)
                    .clipped()
                Spacer()
            }
            
            VStack(spacing: 0) {
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.clear, location: 0),
                        .init(color: Color.appBg.opacity(0.7), location: 1)
                    ]),
                    startPoint: .center,
                    endPoint: .bottom
                )
                .frame(minHeight: 150)
                .onTapGesture {
                    tapAction?(root)
                }
                
                ZStack {
                    Color.appBg.opacity(0.7) // hide the weird white strip above when the reply is tapped.
                    reply
                }
            }
        }
    }
}

struct ThreadRootView_Previews: PreviewProvider {
    static var previewData = PreviewData()
    
    static var previews: some View {
        ScrollView {
            VStack {
                ThreadRootView(root: previewData.longNote, tapAction: { _ in }) {
                    
                }
            }
        }
        .background(Color.appBg)
        .inject(previewData: previewData)
    }
}
