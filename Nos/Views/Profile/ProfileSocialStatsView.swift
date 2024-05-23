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
                router.currentPath.wrappedValue.append(
                    FollowsDestination(
                        author: author,
                        follows: followsResult.compactMap { $0.destination }
                    )
                )
            } label: {
                tab(label: .localizable.following, value: author.follows.count)
            }
            spacer
            Button {
                router.currentPath.wrappedValue.append(
                    RelaysDestination(
                        author: author,
                        relays: author.relays.map { $0 }
                    )
                )
            } label: {
                tab(label: .localizable.relays, value: author.relays.count)
            }
            spacer
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical, 9)
    }

    private func tab(label: LocalizedStringResource, value: Int) -> some View {
        VStack {
            Text("\(value)")
                .font(.title3.bold())
                .foregroundColor(.primaryTxt)
            Text(String(localized: label).lowercased())
                .font(.footnote)
                .dynamicTypeSize(...DynamicTypeSize.xLarge)
                .foregroundColor(.secondaryTxt)
        }
    }
}
