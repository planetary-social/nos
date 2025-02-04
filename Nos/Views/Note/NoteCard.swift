import SwiftUI
import Logger
import CoreData
import Dependencies

/// This view displays the information we have for a message suitable for being used in a list or grid.
///
/// Use this view inside MessageButton to have nice borders.
struct NoteCard: View {

    @ObservedObject var note: Event
    @State private var quotedNote: Event?
    
    let style: CardStyle

    @State private var warningController = NoteWarningController()

    @EnvironmentObject private var router: Router

    private let shouldTruncate: Bool
    private let repliesDisplayType: RepliesDisplayType
    
    /// Indicates whether the number of likes is displayed.
    private let showsLikeCount: Bool

    /// Indicates whether the number of reposts is displayed.
    private let showsRepostCount: Bool
    
    private let hideOutOfNetwork: Bool
    private let rendersQuotedNotes: Bool
    private let showsActions: Bool
    private let replyAction: ((Event) -> Void)?
    
    /// Initializes a NoteCard object.
    ///
    /// - Parameter note: Note event to display.
    /// - Parameter style: Card style. Defaults to `.compact`.
    /// - Parameter shouldTruncate: Whether the card should display just some lines or the
    /// full content of the note. Defaults to `true`.
    /// - Parameter hideOutOfNetwork: Blur the card if the author is not inside the user's
    /// network. Defaults to `true`.
    /// - Parameter repliesDisplayType: Replies Label style. Defaults to `.displayNothing`.
    /// - Parameter showsLikeCount: Whether the number of likes is displayed. Defaults to `true`.
    /// - Parameter showsRepostCount: Whether the number of reposts is displayed. Defaults to `true`.
    /// - Parameter replyAction: Handler that gets called when the user taps on the Reply
    /// button. Defaults to `nil`.
    init(
        note: Event,
        style: CardStyle = .compact,
        shouldTruncate: Bool = true,
        hideOutOfNetwork: Bool = true,
        rendersQuotedNotes: Bool = true,
        showsActions: Bool = true,
        repliesDisplayType: RepliesDisplayType = .displayNothing,
        showsLikeCount: Bool = true,
        showsRepostCount: Bool = true,
        replyAction: ((Event) -> Void)? = nil
    ) {
        self.note = note
        self.style = style
        self.shouldTruncate = shouldTruncate
        self.hideOutOfNetwork = hideOutOfNetwork
        self.rendersQuotedNotes = rendersQuotedNotes
        self.showsActions = showsActions
        self.repliesDisplayType = repliesDisplayType
        self.showsLikeCount = showsLikeCount
        self.showsRepostCount = showsRepostCount
        self.replyAction = replyAction
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            switch style {
            case .compact:
                VStack(spacing: 0) {
                    HStack(alignment: .center, spacing: 0) {
                        if !warningController.showWarning {
                            if let author = note.author {
                                Button {
                                    router.push(author)
                                } label: {
                                    NoteCardHeader(note: note, author: author)
                                }
                            }
                            Spacer()
                            NoteOptionsButton(note: note)
                        } else {
                            Spacer()
                        }
                    }
                    .padding(5)
                    .allowsHitTesting(!note.isPreview)
                    
                    Divider()
                        .overlay(Color.cardDividerTop)
                        .shadow(color: .cardDividerTopShadow, radius: 0, x: 0, y: 1)
                    
                    Group {
                        if note.isStub {
                            HStack {
                                Spacer()
                                ProgressView().foregroundColor(.primaryTxt)
                                Spacer()
                            }
                            .padding(30)
                        } else if note.kind == EventKind.picturePost.rawValue
                        {
                            PictureNoteCard(
                                note: note,
                                showsLikeCount: showsLikeCount,
                                showsRepostCount: showsRepostCount,
                                cornerRadius: cornerRadius,
                                replyAction: replyAction
                            )
                        } else if note.kind == EventKind.picturePost.rawValue ||
                                  note.kind == EventKind.shortVideo.rawValue
                        {
                            VideoNoteCard(
                                note: note,
                                showsLikeCount: showsLikeCount,
                                showsRepostCount: showsRepostCount,
                                cornerRadius: cornerRadius,
                                replyAction: replyAction
                            )
                        } else {
                            CompactNoteView(
                                note: note,
                                shouldTruncate: shouldTruncate,
                                showLinkPreviews: !warningController.showWarning
                            )
                        }
                    }
                    .blur(radius: warningController.showWarning ? 6 : 0)
                    .frame(maxWidth: .infinity)
                    
                    if rendersQuotedNotes, let quotedNote = quotedNote {
                        Button {
                            router.push(quotedNote)
                        } label: {
                            NoteCard(
                                note: quotedNote,
                                hideOutOfNetwork: false,
                                rendersQuotedNotes: false,
                                showsActions: false
                            )
                            .withStyledBorder() // Check that this modifier is correctly defined.
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                        }
                        .allowsHitTesting(!note.isPreview)
                    }
                    
                    BeveledSeparator()
                    
                    HStack(spacing: 0) {
                        if repliesDisplayType != .displayNothing {
                            Button {
                                router.push(note)
                            } label: {
                                RepliesLabel(
                                    repliesDisplayType: repliesDisplayType,
                                    for: note
                                )
                            }
                        }
                        Spacer()
                        if showsActions {
                            RepostButton(note: note, showsCount: showsRepostCount)
                            LikeButton(note: note, showsCount: showsLikeCount)
                            ReplyButton(note: note, replyAction: replyAction)
                        }
                    }
                    .padding(.leading, 13)
                    .padding(.trailing, 5)
                    .padding(.vertical, 5)
                    .allowsHitTesting(!note.isPreview)
                }
                .blur(radius: warningController.showWarning ? 6 : 0)
                .opacity(warningController.showWarning ? 0.3 : 1)
                .frame(minHeight: warningController.showWarning ? 300 : nil)
                .overlay(WarningView(controller: warningController))
                
            case .golden:
                if let author = note.author {
                    GoldenPostView(author: author, note: note)
                } else {
                    EmptyView()
                }
            }
        }
        .task {
            warningController.note = note
            warningController.shouldHideOutOfNetwork = hideOutOfNetwork
        }
        .task {
            await note.loadViewData()
            loadQuotedNote()
        }
        .onChange(of: note.content) { _, _ in
            Task { await note.loadAttributedContent() }
        }
        .onChange(of: note.quotedNoteID) {
            loadQuotedNote()
        }
        .background(
            LinearGradient.cardBackground
                .cornerRadius(cornerRadius)
        )
        .listRowInsets(EdgeInsets())
    }
    
    private func loadQuotedNote() {
        guard rendersQuotedNotes, let quotedNoteID = note.quotedNoteID else {
            return
        }
        
        @Dependency(\.persistenceController) var persistenceController
        quotedNote = try? Event.findOrCreateStubBy(
            id: quotedNoteID,
            context: persistenceController.viewContext
        )
    }

    var cornerRadius: CGFloat {
        switch style {
        case .golden:
            return 15
        case .compact:
            return 20
        }
    }
}

struct NoteCard_Previews: PreviewProvider {
    
    static var previewData = PreviewData()
    static var previews: some View {
        Group {
            ScrollView {
                VStack {
                    NoteCard(note: previewData.longFormNote, hideOutOfNetwork: false)
                    NoteCard(note: previewData.shortNote, hideOutOfNetwork: false)
                    NoteCard(note: previewData.longNote, hideOutOfNetwork: false)
                    NoteCard(note: previewData.imageNote, hideOutOfNetwork: false)
                    NoteCard(note: previewData.expiringNote, hideOutOfNetwork: false)
                    NoteCard(note: previewData.verticalImageNote, hideOutOfNetwork: false)
                    NoteCard(note: previewData.doubleImageNote, hideOutOfNetwork: false)
                    NoteCard(note: previewData.veryWideImageNote, hideOutOfNetwork: false)
                    NoteCard(note: previewData.imageNote, style: .golden, hideOutOfNetwork: false)
                    NoteCard(note: previewData.linkNote, hideOutOfNetwork: false)
                }
            }
        }
        .environment(\.managedObjectContext, previewData.previewContext)
        .environment(previewData.relayService)
        .environmentObject(previewData.router)
        .environment(previewData.currentUser)
        .padding()
        .background(Color.appBg)
    }
}
