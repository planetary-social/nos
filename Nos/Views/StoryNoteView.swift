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

    @State
    private var shouldShowSpacing = false

    @State
    private var intrinsicSize = CGSize.zero

    private func updateShouldShowSpacing() {
        shouldShowSpacing = intrinsicSize.height + 140 > minHeight
    }

    @EnvironmentObject var router: Router
    @Dependency(\.persistenceController) private var persistenceController

    internal init(note: Event, minHeight: CGFloat) {
        self.note = note
        self.minHeight = minHeight
    }

    private var isShortTweet: Bool {
        guard let text = note.content, contentLinks.isEmpty, text.count < 281 else {
            return false
        }
        return true
    }

    var font: Font {
        guard let text = note.content, contentLinks.isEmpty, text.count < 281 else {
            return .title3
        }
        return .largeTitle
    }

    var padding: CGFloat {
        if isShortTweet {
            return 30
        } else {
            return 15
        }
    }
    var formattedText: some View {
        noteText
            .textSelection(.enabled)
            .font(font)
            .foregroundColor(.primaryTxt)
            .tint(.accent)
            .padding(padding)
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
            if shouldShowSpacing {
                Spacer(minLength: 85)
            }
            if note.kind == EventKind.text.rawValue, !contentLinks.isEmpty {
                TabView {
                    ForEach(contentLinks, id: \.self.absoluteURL) { url in
                        LinkPreview(url: url)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 0)
                    }
                }
                .tabViewStyle(.page)
                .frame(height: 320)
            }
            formattedText
            if shouldShowSpacing {
                Spacer(minLength: 55)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: minHeight)
        .background {
            GeometryReader { geometryProxy in
                Color.clear.preference(key: IntrinsicSizePreferenceKey.self, value: geometryProxy.size)
            }
        }
        .onPreferenceChange(IntrinsicSizePreferenceKey.self) { newSize in
            if newSize.height > intrinsicSize.height {
                intrinsicSize = newSize
                updateShouldShowSpacing()
            }
        }
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

    fileprivate struct IntrinsicSizePreferenceKey: PreferenceKey {
        static var defaultValue: CGSize = .zero
        static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
    }
}
