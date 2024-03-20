import SwiftUI
import Logger
import Dependencies

/// A view that displays the text of a note (kind: 1 Nostr event) and truncates it with a "Read more" button if
/// it is too long
struct CompactNoteView: View {
    
    @Environment(\.managedObjectContext) private var viewContext

    /// The note whose content will be displayed
    let note: Event
    
    /// The maximum number of lines to show before truncating (if `showFullMessage` is false)
    let truncationLineLimit = 12
    
    /// If true this view will always display the full text of the note. If false and the note is long 
    /// it will be truncated with a button the user can tap to display the full note.
    @State private var showFullMessage: Bool

    /// Whether view displays truncated text with a "Read more" button to display the full text.
    @State private var shouldShowReadMore = false
    
    /// The size of the full note text 
    @State private var intrinsicSize = CGSize.zero
    
    /// The size of the note text truncated to `truncationLineLimit` lines.
    @State private var truncatedSize = CGSize.zero
    
    /// Whether link previews should be displayed for links found in the note text.
    private var showLinkPreviews: Bool
    
    /// If true links will be highlighted and open when tapped. If false the text will change to a secondary color
    /// and links will not be tappable.
    private var allowUserInteraction: Bool
    
    @EnvironmentObject private var router: Router
    @Dependency(\.persistenceController) private var persistenceController
    
    internal init(
        note: Event, 
        showFullMessage: Bool = false, 
        showLinkPreviews: Bool = true,
        allowUserInteraction: Bool = true
    ) {
        _showFullMessage = .init(initialValue: showFullMessage)
        self.note = note
        self.showLinkPreviews = showLinkPreviews
        self.allowUserInteraction = allowUserInteraction
    }
    
    func updateShouldShowReadMore() {
        shouldShowReadMore = intrinsicSize.height > truncatedSize.height + 30
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
                router.open(url: url, with: viewContext)
                return .handled
            })
    }
    
    var noteText: some View {
        Group {
            switch note.attributedContent {
            case .loading:
                SwiftUI.Text(note.content ?? "")
                    .font(.clarity(.regular))
                    .redacted(reason: .placeholder)
            case .loaded(let attributedString):
                SwiftUI.Text(attributedString)
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showFullMessage {
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
                        PlainText(String(localized: .localizable.readMore).uppercased())
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
            if note.kind == EventKind.text.rawValue, showLinkPreviews, !note.contentLinks.isEmpty {
                LinkPreviewCarousel(links: note.contentLinks)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onChange(of: note.attributedContent) {
            updateShouldShowReadMore()
        }
        .task {
            await note.loadViewData()
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
