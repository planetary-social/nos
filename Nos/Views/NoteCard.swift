//
//  NoteCard.swift
//  Planetary
//
//  Created by Martin Dutra on 25/10/22.
//  Copyright © 2022 Verse Communications Inc. All rights reserved.
//

import SwiftUI
import Logger
import CoreData
import Dependencies

/// This view displays the information we have for an message suitable for being used in a list or grid.
///
/// Use this view inside MessageButton to have nice borders.
struct NoteCard: View {

    @ObservedObject var note: Event
    
    var style = CardStyle.compact
    
    @State private var subscriptionIDs = [RelaySubscription.ID]()
    @State private var userTappedShowOutOfNetwork = false
    @State private var replyCount = 0
    @State private var replyAvatarURLs = [URL]()
    @State private var reportingAuthors = [Author]()
    @State private var reports = [Event]()
    @State private var isOverlayHelpTextBoxShown: Bool = false
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var relayService: RelayService
    @EnvironmentObject private var currentUser: CurrentUser
    @Dependency(\.persistenceController) var persistenceController

    private var showFullMessage: Bool
    private let showReplyCount: Bool
    private var hideOutOfNetwork: Bool
    private var replyAction: ((Event) -> Void)?
    
    private var showContents: Bool {
        (!hasContentWarning && !hideOutOfNetwork) ||
        userTappedShowOutOfNetwork ||
        (!hasContentWarning && (currentUser.socialGraph.contains(note.author?.hexadecimalPublicKey) ||
        Event.discoverTabUserIdToInfo.keys.contains(note.author?.hexadecimalPublicKey ?? "")))
    }
    
    private var reportReason: String {
        let reported = note.reports(followedBy: self.currentUser)
        return(reported.first?.content ?? "")
    }
    
    private var reportEvents: [Event] {
        note.reports(followedBy: self.currentUser)
    }
    
    private var authorReports: [Event] {
        if (note.author != nil) {
            let reports =  note.reports(referencingAuthor: note.author!, followedBy: self.currentUser)

        }
        
        if let author = note.author {
            let reports = author.lookupReportsOnAuthor(context: viewContext)
            if reports.count > 0 {
                print(reports)
            }
            return reports
        }
        return []
    }
 
    private var hasContentWarning: Bool {
        reportEvents.count > 0 || authorReports.count > 0
    }
    
    private var attributedReplies: AttributedString? {
        if replyCount == 0 {
            return nil
        }
        let replyCount = replyCount
        let localized = replyCount == 1 ? Localized.Reply.one : Localized.Reply.many
        let string = localized.text(["count": "**\(replyCount)**"])
        do {
            var attributed = try AttributedString(markdown: string)
            if let range = attributed.range(of: "\(replyCount)") {
                attributed[range].foregroundColor = .primaryTxt
            }
            return attributed
        } catch {
            return nil
        }
    }
    
    init(
        note: Event,
        style: CardStyle = .compact,
        showFullMessage: Bool = false,
        hideOutOfNetwork: Bool = true,
        showReplyCount: Bool = true,
        replyAction: ((Event) -> Void)? = nil,
        reported: Bool = false,
        labeled: Bool = false
    ) {
        self.note = note
        self.style = style
        self.showFullMessage = showFullMessage
        self.hideOutOfNetwork = hideOutOfNetwork
        self.showReplyCount = showReplyCount
        self.reportingAuthors = reportingAuthors
        self.replyAction = replyAction
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            switch style {
            case .compact:
                VStack {
                    HStack(alignment: .center, spacing: 0) {
                        if let author = note.author {
                            Button {
                                router.currentPath.wrappedValue.append(author)
                            } label: {
                                NoteCardHeader(note: note, author: author)
                            }
                            NoteOptionsButton(note: note)
                        }
                    }
                    
                    Divider().overlay(Color.cardDivider).shadow(color: .cardDividerShadow, radius: 0, x: 0, y: 1)
                    Group {
                        if note.isStub {
                            HStack {
                                Spacer()
                                ProgressView().foregroundColor(.primaryTxt)
                                Spacer()
                            }
                            .padding(30)
                            .frame(maxWidth: .infinity)
                        } else {
                            CompactNoteView(note: note, showFullMessage: showFullMessage)
                                .blur(radius: showContents ? 0 : 6)
                                .frame(maxWidth: .infinity)
                        }
                        BeveledSeparator()
                        HStack(spacing: 0) {
                            if showReplyCount {
                                StackedAvatarsView(avatarUrls: replyAvatarURLs, size: 20, border: 0)
                                    .padding(.trailing, 8)
                                if let replies = attributedReplies {
                                    Text(replies)
                                        .font(.subheadline)
                                        .foregroundColor(Color.secondaryText)
                                }
                            }
                            Spacer()
                            
                            RepostButton(note: note) {
                                await repostNote()
                            }
                            
                            LikeButton(note: note) {
                                await likeNote()
                            }
                            
                            // Reply button
                            Button(action: {
                                if let replyAction {
                                    replyAction(note)
                                } else {
                                    router.push(ReplyToNavigationDestination(note: note))
                                }
                            }, label: {
                                Image.buttonReply
                                    .padding(.leading, 10)
                                    .padding(.trailing, 23)
                                    .padding(.vertical, 12)
                            })
                        }
                        .padding(.leading, 13)
                    }
                }
                .blur(radius: showContents ? 0 : 6)
                .opacity(showContents ? 1 : 0.3)
                .frame(minHeight: showContents ? 130 : hasContentWarning ? 300 : nil)
                
                .overlay(
                    !showContents ? OverlayView(
                        userTappedShowAction: {
                            userTappedShowOutOfNetwork = true
                        }, 
                        hasContentWarning: hasContentWarning,
                        reports: reportEvents + authorReports,
                        isOverlayHelpTextBoxShown: $isOverlayHelpTextBoxShown) : nil
                )
            case .golden:
                if let author = note.author {
                    GoldenPostView(author: author, note: note)
                } else {
                    EmptyView()
                }
            }
        }
        .task {
            if note.isStub {
                _ = await relayService.requestEvent(with: note.identifier)
            } 
            self.reportingAuthors = note.reportingAuthors(followedBy: currentUser)
            print(self.reportingAuthors)
        }
        .onAppear {
            Task(priority: .userInitiated) {
                await subscriptionIDs += Event.requestAuthorsMetadataIfNeeded(
                    noteID: note.identifier,
                    using: relayService,
                    in: persistenceController.backgroundViewContext
                )
            }
        }
        .onAppear {
            note.viewedAt = Date() // Update the `viewedAt` property to the current date and time
        }
        .onDisappear {
            Task(priority: .userInitiated) {
                await relayService.decrementSubscriptionCount(for: subscriptionIDs)
                subscriptionIDs.removeAll()
            }
        }
        .background(LinearGradient.cardBackground)
        .task {
            if showReplyCount {
                let (replyCount, replyAvatarURLs) = await Event.replyMetadata(
                    for: note.identifier, 
                    context: persistenceController.backgroundViewContext
                )
                self.replyCount = replyCount
                self.replyAvatarURLs = replyAvatarURLs
            }
        }
        .listRowInsets(EdgeInsets())
        .cornerRadius(cornerRadius)
    }
    
    struct OverlayView: View {
        var userTappedShowAction: () -> Void
        var hasContentWarning: Bool
        var reports: [Event]
        @Binding var isOverlayHelpTextBoxShown: Bool
    
        @ViewBuilder
        var body: some View {
            if hasContentWarning  {
                OverlayContentReportView(userTappedShowAction: userTappedShowAction, reports: reports, isOverlayHelpTextBoxShown: $isOverlayHelpTextBoxShown)
            } else {
                OverlayOutofNetworkView(userTappedShowAction: userTappedShowAction, isOverlayHelpTextBoxShown: $isOverlayHelpTextBoxShown)
            }
        }
    }
    
    struct OverlayOutofNetworkView: View {
        @State private var isTextBoxShown: Bool = false
        var userTappedShowAction: () -> Void
        @Binding var isOverlayHelpTextBoxShown: Bool

        var body: some View {
            VStack(alignment: .leading) {
                HStack {
                    Spacer()
                    Button(action: {
                        self.isOverlayHelpTextBoxShown.toggle()
                    }) {
                        (isTextBoxShown ? Image.x : Image.info)
                            .resizable()
                            .frame(width: 24, height: 24)
                    }
                    .padding(.trailing, 24)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 24)

                // Center align the content
                VStack(alignment: .center) {
                    Spacer() // pushes content to the center

                    if self.isOverlayHelpTextBoxShown {
                        Localized.outsideNetworkExplanation.view
                            .font(.body)
                            .foregroundColor(.secondaryText)
                            .background {
                                Color.cardBackground
                                    .blur(radius: 8, opaque: false)
                            }
                            .padding(.horizontal, 24)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Localized.outsideNetwork.view
                            .font(.body)
                            .foregroundColor(.secondaryText)
                            .background {
                                Color.cardBackground
                                    .blur(radius: 8, opaque: false)
                            }
                            .padding(.horizontal, 24)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    SecondaryActionButton(title: Localized.viewThisPostAnyway) {
                        withAnimation {
                            userTappedShowAction()
                        }
                    }
                    .padding(.top, 10) // Move the button closer to the text

                    Spacer() // pushes content to the center
                }
                .frame(maxWidth: .infinity) // Allow the VStack to take full width
                Spacer(minLength: 30) // Ensure there's some spacing at the bottom
            }
        }
    }

    struct OverlayContentReportView: View {
        @State private var isTextBoxShown: Bool = false
        var userTappedShowAction: () -> Void
        var reports: [Event]
        @Binding var isOverlayHelpTextBoxShown: Bool

        // Assuming each 'Event' has an 'Author' and we can get an array of 'Author' names
        private var authorNames: [String] {
            // Extracting author names. Adjust according to your actual data structure.
            reports.compactMap { $0.author?.name }
        }

        // Assuming there's a property or method 'safeName' in 'Author' that safely returns the author's name.
        private var firstAuthorSafeName: String {
            // Getting the safe name of the first author. Adjust according to your actual data structure.
            reports.first?.author?.safeName ?? "Unknown Author"
        }

        private var reason: String {
            reports.first?.content ?? ""
        }
        
        var body: some View {
            VStack(alignment: .leading) {
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation {
                            self.isOverlayHelpTextBoxShown.toggle()
                        }
                    }) {
                        (isTextBoxShown ? Image.x : Image.info)
                            .resizable()
                            .frame(width: 24, height: 24)
                    }
                    .padding(.trailing, 24)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 24)

                // Center align the content
                VStack(alignment: .center) {
                    Spacer() // pushes content to the center
                    
                    // TextBox or Image based on isTextBoxShown
                    if self.isOverlayHelpTextBoxShown {
                        Localized.contentWarningExplanation.view
                            .font(.body)
                            .foregroundColor(.secondaryText)
                            .padding(.horizontal, 24)
                            .fixedSize(horizontal: false, vertical: true)
                            .layoutPriority(1)
                    } else {

                        Image.warningEye
                            .scaledToFit()
                            .frame(width: 48, height: 48) // Set the width and height to 48
                            .padding(.bottom, 20)
                            
                        Text( reason )
                            .font(.body)
                            .foregroundColor(.secondaryText)
                            .background {
                                Color.cardBackground
                                    .blur(radius: 8, opaque: false)
                            }
                        
                        // Reporting author names with localization
                        if authorNames.count > 1 {
                            Text(Localized.reportedByOneAndMore.localizedMarkdown([
                                "one": firstAuthorSafeName,
                                "count": "\(authorNames.count - 1)"
                            ]))
                            .font(.body)  // Adjust font and style as needed
                            .foregroundColor(.primary)
                            .padding(.leading, 25)  // Adjust padding as needed
                        } else {
                            Text(Localized.reportedByOne.localizedMarkdown([
                                "one": firstAuthorSafeName
                            ]))
                            .font(.body)  // Adjust font and style as needed
                            .foregroundColor(.secondaryText)
                            .padding(.leading, 25)  // Adjust padding as needed
                        }
                    }
                    SecondaryActionButton(title: Localized.viewThisPostAnyway) {
                        withAnimation {
                            userTappedShowAction()
                        }
                    }
                    .padding(.top, 10) // Move the button closer to the text

                    Spacer() // pushes content to the center
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                Spacer(minLength: 30) // Ensure there's some spacing at the bottom

            }
        }
    }
    
    // we need to still look for associated lables
    struct OverlayContentLabelView: View{
        var userTappedShowAction: () -> Void
        
        var body: some View {
            VStack {
                Localized.outsideNetwork.view
                    .font(.body)
                    .foregroundColor(.secondaryText)
                    .background {
                        Color.cardBackground
                            .blur(radius: 8, opaque: false)
                    }
                    .padding(20)
                SecondaryActionButton(title: Localized.show) {
                    withAnimation {
                        userTappedShowAction()
                    }
                }
            }
        }
    }
    func likeNote() async {
        
        guard let keyPair = currentUser.keyPair else {
            return
        }
        
        var tags: [[String]] = []
        if let eventReferences = note.eventReferences.array as? [EventReference] {
            // compactMap returns an array of the non-nil results.
            tags += eventReferences.compactMap { event in
                guard let eventId = event.eventId else { return nil }
                return ["e", eventId]
            }
        }

        if let authorReferences = note.authorReferences.array as? [EventReference] {
            tags += authorReferences.compactMap { author in
                guard let eventId = author.eventId else { return nil }
                return ["p", eventId]
            }
        }

        if let id = note.identifier {
            tags.append(["e", id] + note.seenOnRelayURLs)
        }
        if let pubKey = note.author?.publicKey?.hex {
            tags.append(["p", pubKey])
        }
        
        let jsonEvent = JSONEvent(
            pubKey: keyPair.publicKeyHex,
            kind: .like,
            tags: tags,
            content: "+"
        )
        
        do {
            try await relayService.publishToAll(event: jsonEvent, signingKey: keyPair, context: viewContext)
        } catch {
            Log.info("Error creating event for like")
        }
    }
    
    func repostNote() async {
        guard let keyPair = currentUser.keyPair else {
            return
        }
        
        var tags: [[String]] = []
        if let id = note.identifier {
            tags.append(["e", id] + note.seenOnRelayURLs)
        }
        if let pubKey = note.author?.publicKey?.hex {
            tags.append(["p", pubKey])
        }
        
        let jsonEvent = JSONEvent(
            pubKey: keyPair.publicKeyHex,
            kind: .repost,
            tags: tags,
            content: note.jsonString ?? ""
        )
        
        do {
            try await relayService.publishToAll(event: jsonEvent, signingKey: keyPair, context: viewContext)
        } catch {
            Log.info("Error creating event for like")
        }
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
                    NoteCard(note: previewData.verticalImageNote, hideOutOfNetwork: false)
                    NoteCard(note: previewData.veryWideImageNote, hideOutOfNetwork: false)
                    NoteCard(note: previewData.imageNote, style: .golden, hideOutOfNetwork: false)
                    NoteCard(note: previewData.linkNote, hideOutOfNetwork: false)
                }
            }
        }
        .environment(\.managedObjectContext, previewData.previewContext)
        .environmentObject(previewData.relayService)
        .environmentObject(previewData.router)
        .environmentObject(previewData.currentUser)
        .padding()
        .background(Color.appBg)
    }
}
