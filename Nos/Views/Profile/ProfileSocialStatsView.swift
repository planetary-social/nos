import SwiftUI

struct ProfileSocialStatsView: View {

    @EnvironmentObject private var router: Router

    var author: Author

    var followsResult: FetchedResults<Follow>

    var body: some View {
        HStack {
            Group {
                Spacer()
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
                Spacer(minLength: 0)
            }
            Group {
                Spacer(minLength: 0)
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
                Spacer(minLength: 0)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical)
    }

    private func tab(label: LocalizedStringResource, value: Int) -> some View {
        VStack {
            Text("\(value)")
                .font(.title)
                .foregroundColor(.primaryTxt)
            Text(String(localized: label).lowercased())
                .font(.subheadline)
                .dynamicTypeSize(...DynamicTypeSize.xLarge)
                .foregroundColor(.secondaryTxt)
        }
    }
}
