import SwiftUI

struct ProfileSocialStatsView: View {

    @EnvironmentObject private var router: Router

    var author: Author

    var followsResult: FetchedResults<Follow>

    private var spacer: some View {
        Spacer(minLength: 25)
    }

    var body: some View {
        HStack(spacing: 0) {
            spacer
            Button {
                router.push(
                    FollowsDestination(
                        author: author,
                        follows: followsResult.compactMap { $0.destination }
                    )
                )
            } label: {
                tab(label: "following", value: author.follows.count)
            }
            spacer
            Button {
                router.push(
                    RelaysDestination(
                        author: author,
                        relays: author.relays.map { $0 }
                    )
                )
            } label: {
                tab(label: "relays", value: author.relays.count)
            }
            spacer
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical, 9)
    }

    private func tab(label: LocalizedStringKey, value: Int) -> some View {
        VStack {
            Text("\(value)")
                .font(.title3.bold())
                .foregroundColor(.primaryTxt)
            Text(label)
                .textCase(.lowercase)
                .font(.footnote)
                .dynamicTypeSize(...DynamicTypeSize.xLarge)
                .foregroundColor(.secondaryTxt)
        }
    }
}
