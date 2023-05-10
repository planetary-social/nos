//
//  CompactNoteView.swift
//  Planetary
//
//  Created by Martin Dutra on 28/10/22.
//  Copyright © 2022 Verse Communications Inc. All rights reserved.
//

import SwiftUI
import Logger
import Down

/// A view that displays the text of a note (kind: 1 Nostr event) and truncates it with a "Read more" button if
/// it is too long
struct CompactNoteView: View {
    
    @Environment(\.managedObjectContext) private var viewContext

    var note: Event

    @State private var shouldShowReadMore = false
    @State var showFullMessage: Bool
    @State private var intrinsicSize = CGSize.zero
    @State private var truncatedSize = CGSize.zero
    @State private var attributedContent: AttributedString
    
    @EnvironmentObject var router: Router
    
    internal init(note: Event, showFullMessage: Bool = false) {
        _attributedContent = .init(initialValue: AttributedString(note.content ?? ""))
        _showFullMessage = .init(initialValue: showFullMessage)
        
        // Parse markdown of long form events
        if note.kind == EventKind.longFormContent.rawValue {
            do {
                let markdown = Down(markdownString: note.content ?? "")
                let style = "* {font-family: Helvetica } code, pre { font-family: Menlo }"
                let attributedString = try markdown.toAttributedString(stylesheet: style)
                _attributedContent = .init(initialValue: AttributedString(attributedString))
            } catch {
                Log.info("Could not parse markdown for note with id: \(String(describing: note.identifier))")
            }
        } 
        self.note = note
    }
    
    func updateShouldShowReadMore() {
        shouldShowReadMore = intrinsicSize.height > truncatedSize.height 
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showFullMessage {
                Text(attributedContent)
                    .font(.body)
                    .foregroundColor(.primaryTxt)
                    .accentColor(.accent)
                    .padding(15)
                    .environment(\.openURL, OpenURLAction { url in
                        router.open(url: url, with: viewContext)
                        return .handled
                    })
            } else {
                Text(attributedContent)
                    .lineLimit(12)
                    .font(.body)
                    .foregroundColor(.primaryTxt)
                    .accentColor(.accent)
                    .padding(15)
                    .environment(\.openURL, OpenURLAction { url in
                        router.open(url: url, with: viewContext)
                        return .handled
                    })
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
                        Text(attributedContent)
                            .font(.body)
                            .padding(15)
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
                            .foregroundColor(.secondaryTxt)
                            .padding(EdgeInsets(top: 4, leading: 6, bottom: 4, trailing: 6))
                            .background(Color.hashtagBg)
                            .cornerRadius(4)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0))
            }
            if let url = try? note
                .content?
                .findUnformattedLinks()
                .first(where: { $0.isImage }) {
                SquareImage(url: url)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task {
            let backgroundContext = PersistenceController.backgroundViewContext
            if let parsedAttributedContent = await Event.attributedContent(
                noteID: note.identifier,
                context: backgroundContext
            ) {
                withAnimation {
                    attributedContent = parsedAttributedContent
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
    
    static var previews: some View {
        Group {
            VStack {
                CompactNoteView(note: PreviewData.shortNote)
            }
            VStack {
                CompactNoteView(note: PreviewData.longNote)
            }
            VStack {
                CompactNoteView(note: PreviewData.longFormNote)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .environmentObject(PreviewData.router)
        .environment(\.managedObjectContext, PreviewData.previewContext)
    }
}
