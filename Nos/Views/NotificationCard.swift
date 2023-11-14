//
//  NotificationsCard.swift
//  Nos
//
//  Created by Matthew Lorentz on 4/28/23.
//

import SwiftUI
import Dependencies

/// A view that details some interaction (reply, like, follow, etc.) with one of your notes.
struct NotificationCard: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var relayService: RelayService
    @Dependency(\.persistenceController) private var persistenceController
    
    @ObservedObject private var viewModel: NotificationViewModel
    @State private var subscriptionIDs = [RelaySubscription.ID]()
    @State private var content: AttributedString?
    
    init(viewModel: NotificationViewModel) {
        self.viewModel = viewModel
    }
    
    func showNote() {
        guard let note = Event.find(by: viewModel.noteID, context: viewContext) else {
            return 
        }
        router.notificationsPath.append(note.referencedNote() ?? note)
    }
    
    var body: some View {
        Button {
            showNote()
        } label: {
            HStack {
                AvatarView(imageUrl: viewModel.authorProfilePhotoURL, size: 40)
                    .shadow(radius: 10, y: 4)
                
                VStack {
                    HStack {
                        Text(viewModel.actionText)
                            .lineLimit(1)
                        Spacer()
                    }
                    HStack {
                        let contentText = Text("\"" + (content ?? "") + "\"")
                            .lineLimit(2)
                            .font(.body)
                            .foregroundColor(.primaryTxt)
                            .tint(.accent)
                        
                        if viewModel.content == nil {
                            contentText.redacted(reason: .placeholder)
                        } else {
                            contentText
                        }
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity)
                
                VStack {
                    Spacer()
                    Text(viewModel.date.distanceFromNowString())
                        .lineLimit(1)
                        .font(.body)
                        .foregroundColor(.secondaryText)
                }
            }
            .padding(10)
            .background(
                LinearGradient(
                    colors: [Color.cardBgTop, Color.cardBgBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(20)
            .padding(.horizontal, 15)
        }
        .buttonStyle(CardButtonStyle(style: .compact))
        .onAppear {
            Task(priority: .userInitiated) {
                let backgroundContext = persistenceController.backgroundViewContext
                await subscriptionIDs += Event.requestAuthorsMetadataIfNeeded(
                    noteID: viewModel.id,
                    using: relayService,
                    in: persistenceController.parseContext
                )
            }
        }
        .onDisappear {
            Task(priority: .userInitiated) {
                await relayService.decrementSubscriptionCount(for: subscriptionIDs)
                subscriptionIDs.removeAll()
            }
        }
        .task(priority: .userInitiated) {
            self.content = await viewModel.loadContent(in: persistenceController.parseContext)
        }
    }
}
