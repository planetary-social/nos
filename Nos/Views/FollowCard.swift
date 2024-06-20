import SwiftUI

/// This view displays the information we have for an message suitable for being used in a list or grid.
///
/// Use this view inside MessageButton to have nice borders.
struct FollowCard: View {

    @ObservedObject var author: Author
    
    var style = CardStyle.compact

    @EnvironmentObject private var router: Router
    @Environment(CurrentUser.self) private var currentUser
    @EnvironmentObject private var relayService: RelayService
    
    @State private var relaySubscriptions = SubscriptionCancellables()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Button {
                    router.push(author)
                } label: {
                    HStack(alignment: .center) {
                        AvatarView(imageUrl: author.profilePhotoURL, size: 24)
                        Text(author.safeName)
                            .lineLimit(1)
                            .font(.clarity(.regular, textStyle: .subheadline))
                            .foregroundColor(Color.primaryTxt)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if author.muted {
                            Text(.localizable.muted)
                                .font(.subheadline)
                                .foregroundColor(Color.secondaryTxt)
                        }
                        Spacer()
                        if let currentUser = currentUser.author {
                            FollowButton(currentUserAuthor: currentUser, author: author)
                                .padding(10)
                        }
                    }
                }
                // TODO: Put MessageOptionsButton back here eventually
            }
            .padding(10)
            BeveledSeparator()
        }
        .background(
            LinearGradient(
                colors: [Color.cardBgTop, Color.cardBgBottom],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .listRowInsets(EdgeInsets())
        .cornerRadius(cornerRadius)
        .onAppear {
            Task(priority: .userInitiated) { 
                let subscription = await relayService.requestMetadata(
                    for: author.hexadecimalPublicKey, 
                    since: author.lastUpdatedMetadata
                ) 
                relaySubscriptions.append(subscription) 
            }
        }
        .onDisappear {
            relaySubscriptions.removeAll()
        }
    }

    var cornerRadius: CGFloat {
        switch style {
        case .golden:
            return 15
        case .compact:
            return 15
        }
    }
}
