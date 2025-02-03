import Foundation
import SwiftUI
import CoreData
import Dependencies

/// This view displays the a button with the information we have for a note suitable for being used in a list
/// or grid.
///
/// The button opens the ThreadView for the note when tapped.
struct NoteButton: View {

    var note: Event
    var style = CardStyle.compact
    var shouldTruncate: Bool
    var hideOutOfNetwork: Bool
    var repliesDisplayType: RepliesDisplayType

    /// Indicates whether the number of likes is displayed.
    var showsLikeCount: Bool

    /// Indicates whether the number of reposts is displayed.
    var showsRepostCount: Bool

    /// Whether replies should be fetched from relays.
    var fetchReplies: Bool

    var displayRootMessage: Bool
    var isTapEnabled: Bool
    
    private let replyAction: ((Event) -> Void)?
    private let tapAction: ((Event) -> Void)?
    @State private var relaySubscriptions = SubscriptionCancellables()

    @Environment(RelayService.self) private var relayService
    @EnvironmentObject private var router: Router
    
    /// Initializes a NoteButton object.
    ///
    /// - Parameter note: Note event to display.
    /// - Parameter style: Card style. Defaults to `.compact`.
    /// - Parameter shouldTruncate: Whether the card should display just some lines or the
    /// full content of the note. Defaults to true.
    /// - Parameter hideOutOfNetwork: Blur the card if the author is not inside the user's
    /// network. Defaults to true.
    /// - Parameter repliesDisplayType: Replies Label style. Defaults to `.displayNothing`.
    /// - Parameter showsLikeCount: Whether the number of likes is displayed. Defaults to `true`.
    /// - Parameter showsRepostCount: Whether the number of reposts is displayed. Defaults to `true`.
    /// - Parameter fetchReplies: Whether replies should be fetched from relays. Defaults
    /// to false.
    /// - Parameter displayRootMessage: Display the root note above if the note is a reply.
    /// Defaults to false.
    /// - Parameter isTapEnabled: Enable user interaction in the card. Defaults to true.
    /// - Parameter replyAction: Handler that gets called when the user taps on the Reply
    /// button. Defaults to `nil`.
    /// - Parameter tapAction: Handler that get called when the user taps on the button. If
    /// `nil`, it navigates to RepliesView. Defaults to `nil`.
    init(
        note: Event, 
        style: CardStyle = CardStyle.compact, 
        shouldTruncate: Bool = true, 
        hideOutOfNetwork: Bool = true, 
        repliesDisplayType: RepliesDisplayType = .displayNothing,
        showsLikeCount: Bool = true,
        showsRepostCount: Bool = true,
        fetchReplies: Bool = false,
        displayRootMessage: Bool = false,
        isTapEnabled: Bool = true,
        replyAction: ((Event) -> Void)? = nil,
        tapAction: ((Event) -> Void)? = nil
    ) {
        self.note = note
        self.style = style
        self.shouldTruncate = shouldTruncate
        self.hideOutOfNetwork = hideOutOfNetwork
        self.repliesDisplayType = repliesDisplayType
        self.showsLikeCount = showsLikeCount
        self.showsRepostCount = showsRepostCount
        self.fetchReplies = fetchReplies
        self.displayRootMessage = displayRootMessage
        self.isTapEnabled = isTapEnabled
        self.replyAction = replyAction
        self.tapAction = tapAction
    }

    /// The note displayed in the note card. Could be different from `note` i.e. in the case of a repost.
    var displayedNote: Event {
        if note.kind == EventKind.repost.rawValue,
            let repostedNote = note.repostedNote() {
            return repostedNote
        } else {
            return note
        }
    }

    var body: some View {
        VStack {
            if note.kind == EventKind.repost.rawValue, let author = note.author {
                Button(action: { 
                    router.push(author)
                }, label: { 
                    HStack(alignment: .center) {
                        AuthorLabel(author: author)
                        Image.repostSymbol
                        if let elapsedTime = note.createdAt?.distanceString() {
                            Text(elapsedTime)
                                .lineLimit(1)
                                .font(.clarity(.medium))
                                .foregroundColor(.secondaryTxt)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .readabilityPadding()
                })
            }
            
            let buttonLabel = NoteCard(
                note: displayedNote,
                style: style,
                shouldTruncate: shouldTruncate,
                hideOutOfNetwork: hideOutOfNetwork,
                repliesDisplayType: repliesDisplayType,
                showsLikeCount: showsLikeCount,
                showsRepostCount: showsRepostCount,
                replyAction: replyAction
            )

            let button = Button {
                if let tapAction {
                    tapAction(displayedNote)
                } else {
                    if let referencedNote = displayedNote.referencedNote() {
                        router.push(referencedNote)
                    } else {
                        router.push(displayedNote)
                    }
                }
            } label: {
                buttonLabel
            }
            .buttonStyle(CardButtonStyle(style: style))

            let buttonOrLabel: some View = SwiftUI.Group {
                if isTapEnabled {
                    button
                } else {
                    buttonLabel.mimicCardButtonStyle()
                }
            }

            switch style {
            case .compact:
                let compactButtonOrLabel = buttonOrLabel
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal)
                    .readabilityPadding()
                
                if displayRootMessage, 
                    note.kind != EventKind.repost.rawValue,
                    let root = note.rootNote() ?? note.referencedNote() {
                    
                    ThreadRootView(
                        root: root, 
                        isRootNoteInteractive: !note.isPreview,
                        tapAction: { root in router.push(root) },
                        reply: { compactButtonOrLabel }
                    )
                } else {
                    compactButtonOrLabel
                }
            case .golden:
                buttonOrLabel
            }
        }
        .onAppear {
            if fetchReplies {
                subscribeToReplies()
            }
        }
        .onDisappear {
            relaySubscriptions.removeAll()
        }
    }

    /// Open relays subscriptions asking one reply from anyone and up to four
    /// replies from follows.
    func subscribeToReplies() {
        Task(priority: .userInitiated) {
            // Close out stale requests
            relaySubscriptions.removeAll()
            relaySubscriptions.append(
                await relayService.requestReplyFromAnyone(
                    for: displayedNote.identifier
                )
            )
            relaySubscriptions.append(
                await relayService.requestRepliesFromFollows(
                    for: displayedNote.identifier,
                    limit: 4
                )
            )
        }
    }
}

struct NoteButton_Previews: PreviewProvider {
    
    static var previewData = PreviewData()
    static var previews: some View {
        ScrollView {
            VStack {
                NoteButton(note: previewData.repost, hideOutOfNetwork: false)
                NoteButton(note: previewData.shortNote)
                NoteButton(note: previewData.longNote)
                NoteButton(note: previewData.reply, hideOutOfNetwork: false, displayRootMessage: true)
                NoteButton(note: previewData.doubleImageNote)
            }
        }
        .background(Color.appBg)
        .inject(previewData: previewData)
    }
}
