import SwiftUI
import Logger
import CoreData
import Dependencies

/// This view displays the information we have for an message suitable for being used in a list or grid.
///
/// Use this view inside MessageButton to have nice borders.
struct NoteCard: View {

    var note: Event
    
    var style = CardStyle.compact

    @State private var warningController = NoteWarningController()

    @EnvironmentObject private var router: Router
    @Dependency(\.persistenceController) var persistenceController

    private var shouldTruncate: Bool
    private let repliesDisplayType: RepliesDisplayType
    private var hideOutOfNetwork: Bool
    private var replyAction: ((Event) -> Void)?

    init(
        note: Event,
        style: CardStyle = .compact,
        shouldTruncate: Bool = true,
        hideOutOfNetwork: Bool = true,
        repliesDisplayType: RepliesDisplayType = .none,
        replyAction: ((Event) -> Void)? = nil
    ) {
        self.note = note
        self.style = style
        self.shouldTruncate = shouldTruncate
        self.hideOutOfNetwork = hideOutOfNetwork
        self.repliesDisplayType = repliesDisplayType
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
                    Divider().overlay(Color.cardDividerTop).shadow(color: .cardDividerTopShadow, radius: 0, x: 0, y: 1)
                    Group {
                        if note.isStub {
                            HStack {
                                Spacer()
                                ProgressView().foregroundColor(.primaryTxt)
                                Spacer()
                            }
                            .padding(30)
                        } else {
                            CompactNoteView(
                                note: note, 
                                shouldTruncate: shouldTruncate, 
                                showLinkPreviews: !warningController.showWarning
                            )
                            .blur(radius: warningController.showWarning ? 6 : 0)
                            .frame(maxWidth: .infinity)
                        }
                        BeveledSeparator()
                        HStack(spacing: 0) {
                            if repliesDisplayType != .none {
                                RepliesLabel(
                                    repliesDisplayType: repliesDisplayType,
                                    for: note
                                )
                            }
                            Spacer()
                            RepostButton(note: note) 
                            LikeButton(note: note)
                            ReplyButton(note: note, replyAction: replyAction)
                        }
                        .padding(.leading, 13)
                    }
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
        }
        .onChange(of: note.content) { _, _ in
            Task { await note.loadAttributedContent() }
        }
        .background(LinearGradient.cardBackground)
        .listRowInsets(EdgeInsets())
        .cornerRadius(cornerRadius)
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
        .environmentObject(previewData.relayService)
        .environmentObject(previewData.router)
        .environment(previewData.currentUser)
        .padding()
        .background(Color.appBg)
    }
}
