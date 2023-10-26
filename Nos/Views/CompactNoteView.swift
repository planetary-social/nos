//
//  CompactNoteView.swift
//  Planetary
//
//  Created by Martin Dutra on 28/10/22.
//  Copyright © 2022 Verse Communications Inc. All rights reserved.
//

import SwiftUI
import Logger
import Dependencies

/// A view that displays the text of a note (kind: 1 Nostr event) and truncates it with a "Read more" button if
/// it is too long
struct CompactNoteView: View {
    
    @Environment(\.managedObjectContext) private var viewContext

    var note: Event

    @State private var shouldShowReadMore = false
    @State var showFullMessage: Bool
    @State private var intrinsicSize = CGSize.zero
    @State private var truncatedSize = CGSize.zero
    @State private var noteContent = LoadingContent<AttributedString>.loading
    @State private var contentLinks = [URL]()
    @State private var loadLinks = true
    // the loadLinks doesn't work... not sure why, need help.
    
    @EnvironmentObject var router: Router
    @Dependency(\.persistenceController) private var persistenceController
    
    internal init(note: Event, showFullMessage: Bool = false, loadLinks: Bool = true) {
        _showFullMessage = .init(initialValue: showFullMessage)
        self.note = note
        self.loadLinks = loadLinks
    }
    
    func updateShouldShowReadMore() {
        shouldShowReadMore = intrinsicSize.height > truncatedSize.height 
    }
    
    var formattedText: some View {
        noteText
            .font(.body)
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
        VStack(alignment: .leading, spacing: 0) {
            if showFullMessage {
                formattedText
            } else {
                formattedText
                    .lineLimit(12)
                    .background {
                        GeometryReader { geometryProxy in
                            Color.clear.preference(key: TruncatedSizePreferenceKey.self, value: geometryProxy.size)
                        }
                    }
                    .onPreferenceChange(TruncatedSizePreferenceKey.self) { newSize in
                        if newSize.height > truncatedSize.height {
                            truncatedSize = newSize
                            updateShouldShowReadMore()
                        }
                    }
                    .background {
                        noteText
                            .fixedSize(horizontal: false, vertical: true)
                            .hidden()
                            .background {
                                GeometryReader { geometryProxy in
                                    Color.clear.preference(
                                        key: IntrinsicSizePreferenceKey.self,
                                        value: geometryProxy.size
                                    )
                                }
                            }
                            .onPreferenceChange(IntrinsicSizePreferenceKey.self) { newSize in
                                if newSize.height > intrinsicSize.height {
                                    intrinsicSize = newSize
                                    updateShouldShowReadMore()
                                }
                            }
                    }
            }
            if shouldShowReadMore && !showFullMessage {
                ZStack(alignment: .center) {
                    Button {
                        withAnimation {
                            showFullMessage = true
                        }
                    } label: {
                        PlainText(Localized.readMore.string.uppercased())
                            .font(.caption)
                            .foregroundColor(.secondaryText)
                            .padding(EdgeInsets(top: 4, leading: 6, bottom: 4, trailing: 6))
                            .background(Color.hashtagBg)
                            .cornerRadius(4)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0))
            }
            if note.kind == EventKind.text.rawValue, loadLinks, !contentLinks.isEmpty {
                LinkPreviewCarousel(links: contentLinks)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

fileprivate struct IntrinsicSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}

fileprivate struct TruncatedSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}

struct CompactNoteView_Previews: PreviewProvider {
    
    static var previewData = PreviewData()
    
    static var previews: some View {
        Group {
            CompactNoteView(note: previewData.linkNote)
            CompactNoteView(note: previewData.shortNote)
            CompactNoteView(note: previewData.longNote)
            CompactNoteView(note: previewData.longFormNote)
            CompactNoteView(note: previewData.doubleImageNote)
        }
        .padding()
        .background(Color.cardBackground)
        .inject(previewData: PreviewData())
    }
}
