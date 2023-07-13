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

import SwiftUI
import LinkPresentation

struct LinkPreview: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> LPLinkView {
        let metadataProvider = LPMetadataProvider()
        let linkView = LPLinkView(url: url)
        
        metadataProvider.startFetchingMetadata(for: url) { metadata, _ in
            if let metadata = metadata {
                DispatchQueue.main.async {
                    linkView.metadata = metadata
                }
            }
        }
        return linkView
    }
    
    func updateUIView(_ uiView: LPLinkView, context: Context) {}
}

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
    @State private var contentLinks = [URL]()
    
    @EnvironmentObject var router: Router
    @Dependency(\.persistenceController) private var persistenceController
    
    internal init(note: Event, showFullMessage: Bool = false) {
        _attributedContent = .init(initialValue: AttributedString(note.content ?? ""))
        _showFullMessage = .init(initialValue: showFullMessage)
        
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
                    .tint(.accent) 
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
                    .tint(.accent) 
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
                            .foregroundColor(.secondaryText)
                            .padding(EdgeInsets(top: 4, leading: 6, bottom: 4, trailing: 6))
                            .background(Color.hashtagBg)
                            .cornerRadius(4)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0))
            }
            if note.kind == EventKind.text.rawValue, !contentLinks.isEmpty {
                VStack {
                    ForEach(contentLinks) { url in
                        LinkPreview(url: url)
                            .padding(.horizontal, 15)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task {
            let backgroundContext = persistenceController.backgroundViewContext
            if let parsedAttributedContent = await Event.attributedContent(
                noteID: note.identifier,
                context: backgroundContext
            ) {
                withAnimation {
                    (self.attributedContent, self.contentLinks) = parsedAttributedContent
                }
            }
        }
    }
}

extension URL: Identifiable {
    public var id: String { UUID().uuidString }
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
