import SwiftUI
import Logger
import Dependencies

/// A view that displays the text of a note (kind: 1 Nostr event) and truncates it with a "Read more" button if
/// it is too long
struct CompactNoteView: View {
    
    /// The note whose content will be displayed
    private let note: Event
    
    /// The maximum number of lines to show before truncating (if `showFullMessage` is false)
    private let truncationLineLimit = 12
    
    /// If true this view will truncate long notes and show a "Read more" button to view the whole thing. If false 
    /// the full note will always be displayed
    private var shouldTruncate: Bool
    
    /// Whether link previews should be displayed for links found in the note text.
    private var showLinkPreviews: Bool
    
    /// If true links will be highlighted and open when tapped. If false the text will change to a secondary color
    /// and links will not be tappable.
    private var allowUserInteraction: Bool

    /// The feature flags to use to determine what features are enabled.
    @Dependency(\.featureFlags) private var featureFlags

    /// Whether this view is currently displayed in a truncated state
    @State private var isTextTruncated = true

    /// The size of the full note text 
    @State private var intrinsicSize = CGSize.zero
    
    /// The size of the note text truncated to `truncationLineLimit` lines.
    @State private var truncatedSize = CGSize.zero
    
    @EnvironmentObject private var router: Router
    
    internal init(
        note: Event, 
        shouldTruncate: Bool = false, 
        showLinkPreviews: Bool = true,
        allowUserInteraction: Bool = true
    ) {
        self.note = note
        self.shouldTruncate = shouldTruncate
        self.showLinkPreviews = showLinkPreviews
        self.allowUserInteraction = allowUserInteraction
    }
    
    /// Calculates whether the note text is long enough to need truncation given `truncationLineLimit`.
    var noteNeedsTruncation: Bool {
        shouldTruncate && intrinsicSize.height > truncatedSize.height + 30 
    }
    
    /// Calculates whether the Read More button should be shown. 
    var showReadMoreButton: Bool {
        noteNeedsTruncation && isTextTruncated
    }

    var category: String {
        switch note.attributedContent {
        case .loading:
            return "Loading"
        case .loaded(let attributedString):
            do {
                let model = try NosTextClassifier()
                let prediction = try model.prediction(text: String(attributedString.characters))
                                return prediction.label
            } catch {
                return "Error"
            }
        }
    }

    var formattedText: some View {
        noteText
            .font(.body)
            .foregroundColor(allowUserInteraction ? .primaryTxt : .secondaryTxt)
            .tint(allowUserInteraction ? .accent : .secondaryTxt) 
            .padding(15)
            .textSelection(.enabled)
            .environment(\.openURL, OpenURLAction { url in
                guard allowUserInteraction else {
                    return .handled
                }
                router.open(url: url)
                return .handled
            })
    }
    
    var noteText: some View {
        Group {
            switch note.attributedContent {
            case .loading:
                Text(note.content ?? "")
                    .font(.clarity(.regular))
                    .redacted(reason: .placeholder)
            case .loaded(let attributedString):
                Text(attributedString)
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !isTextTruncated || !shouldTruncate {
                formattedText
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                formattedText
                    .lineLimit(truncationLineLimit)
                    .background {
                        GeometryReader { geometryProxy in
                            Color.clear.preference(key: TruncatedSizePreferenceKey.self, value: geometryProxy.size)
                        }
                    }
                    .onPreferenceChange(TruncatedSizePreferenceKey.self) { newSize in
                        if newSize.height > truncatedSize.height {
                            truncatedSize = newSize
                        }
                    }
                    .background {
                        // To calculate whether the text should be truncated we create this hidden view of 
                        // `formattedText` and record its size. It is compared to `truncatedSize` and used in the 
                        // calculation of `noteNeedsTruncation`.
                        formattedText
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
                                }
                            }
                    }
            }
            if showReadMoreButton {
                ZStack(alignment: .center) {
                    Button {
                        withAnimation {
                            isTextTruncated = false
                        }
                    } label: {
                        Text(String(localized: .localizable.readMore).uppercased())
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
            Text(category)
                .foregroundColor(.secondaryTxt)
                .padding(EdgeInsets(top: 4, leading: 6, bottom: 4, trailing: 6))
                .background(Color.hashtagBg)
                .cornerRadius(4)
                .padding()

            if note.kind == EventKind.text.rawValue, showLinkPreviews, !note.contentLinks.isEmpty {
                if featureFlags.newMediaDisplayEnabled {
                    EmptyView()
                } else {
                    LinkPreviewCarousel(links: note.contentLinks)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task {
            await note.loadViewData()
        }
        .task {
            await note.loadAttributedContent()
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
            CompactNoteView(note: previewData.linkNote, allowUserInteraction: false)
            CompactNoteView(note: previewData.shortNote)
            CompactNoteView(note: previewData.longNote)
            CompactNoteView(note: previewData.doubleImageNote)
            CompactNoteView(note: previewData.doubleImageNote, showLinkPreviews: false)
        }
        .padding()
        .background(Color.previewBg)
        .inject(previewData: PreviewData())
    }
}
