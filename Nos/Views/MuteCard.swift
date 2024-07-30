import SwiftUI

/// This view displays the information we have for an message suitable for being used in a list or grid.
///
/// Use this view inside MessageButton to have nice borders.
struct MuteCard: View {

    @ObservedObject var author: Author

    @EnvironmentObject private var router: Router
    @EnvironmentObject private var relayService: RelayService
    
    @State private var relaySubscriptions = SubscriptionCancellables()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Button {
                    router.push(author)
                } label: {
                    HStack {
                        AvatarView(imageUrl: author.profilePhotoURL, size: 24)
                        Text(author.safeName)
                            .lineLimit(1)
                            .font(.clarity(.regular, textStyle: .subheadline))
                            .foregroundColor(Color.primaryTxt)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
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
        .cornerRadius(15)
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
}
