//
//  StoryNoteView.swift
//  Nos
//
//  Created by Martin Dutra on 16/10/23.
//

import SwiftUI
import Logger
import Dependencies

/// A view that displays the text of a note (kind: 1 Nostr event) and truncates it with a "Read more" button if
/// it is too long
struct StoryNoteView: View {

    @Environment(\.managedObjectContext) private var viewContext

    var note: Event
    var minHeight: CGFloat

    @State private var noteContent = LoadingContent<AttributedString>.loading
    @State private var contentLinks = [URL]()

    @EnvironmentObject var router: Router
    @Dependency(\.persistenceController) private var persistenceController

    internal init(note: Event, minHeight: CGFloat) {
        self.note = note
        self.minHeight = minHeight
    }

    var formattedText: some View {
        noteText
            .textSelection(.enabled)
            .font(.title3)
            .foregroundColor(.primaryTxt)
            .tint(.accent)
            .padding(15)
            .environment(\.openURL, OpenURLAction { url in
                router.open(url: url, with: viewContext)
                return .handled
            })
    }

    var noteText: some View {
        Group {
            switch noteContent {
            case .loading:
                Text(note.content ?? "")
                    .redacted(reason: .placeholder)
            case .loaded(let attributedString):
                Text(attributedString)
            }
        }
    }

    var body: some View {
        VStack {
            if note.kind == EventKind.text.rawValue, !contentLinks.isEmpty {
                TabView {
                    ForEach(contentLinks, id: \.self.absoluteURL) { url in
                        LinkPreview(url: url)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 0)
                    }
                }
                .tabViewStyle(.page)
                .frame(maxHeight: 320)
            }
            formattedText
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: minHeight)
        .task {
            let backgroundContext = persistenceController.backgroundViewContext
            if let parsedAttributedContent = await Event.attributedContentAndURLs(
                noteID: note.identifier,
                context: backgroundContext
            ) {
                withAnimation(.easeIn(duration: 0.1)) {
                    let (attributedString, contentLinks) = parsedAttributedContent
                    self.noteContent = .loaded(attributedString)
                    self.contentLinks = contentLinks
                }
            }
        }
    }
}
