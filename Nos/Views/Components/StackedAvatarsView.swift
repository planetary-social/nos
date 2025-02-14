import SwiftUI

/// This view displays a stacked list of avatars as we use it in when displaying replies in a post, and a list of
/// followers/follows/blocks in a profile.
struct StackedAvatarsView: View {
    /// The list of avatars to display
    let avatarUrls: [URL?]

    /// The size of the circle avatar (it doesn't counts the border)
    var size: CGFloat = 26

    /// The size of the border. Use zero if you don't want any background
    var border: CGFloat = 2

    var body: some View {
        ZStack(alignment: .leading) {
            ForEach(Array(zip(avatarUrls.indices, avatarUrls)), id: \.0) { index, avatarUrl in
                AvatarView(imageUrl: avatarUrl, size: size)
                    .offset(x: matrix(avatarUrls.count)[index] * totalSize / 4, y: 0)
            }
        }
        .frame(
            width: avatarUrls.isEmpty ? 0 : totalSize + CGFloat(Int(totalSize) / 2 * (avatarUrls.count - 1)),
            height: totalSize
        )
    }

    private var totalSize: CGFloat {
        size + border * 2
    }

    private func matrix(_ numberOfItems: Int) -> [CGFloat] {
        var startingArray: [CGFloat] = []
        if numberOfItems.isMultiple(of: 2) {
            startingArray = []
        } else {
            startingArray = [0]
        }
        let arrayToAppend = stride(
            from: 1.0 + CGFloat(startingArray.count),
            through: CGFloat(numberOfItems / 2) + CGFloat(startingArray.count),
            by: 1.0
        )
        startingArray.insert(contentsOf: arrayToAppend.map { $0 * -1 }, at: 0)
        startingArray.append(contentsOf: arrayToAppend)
        return startingArray
    }
}

struct StackedAvatarsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack {
                StackedAvatarsView(avatarUrls: [])
                StackedAvatarsView(avatarUrls: [nil])
                StackedAvatarsView(avatarUrls: [nil, nil])
                StackedAvatarsView(avatarUrls: [], size: 20, border: 0)
                StackedAvatarsView(avatarUrls: [nil], size: 20, border: 0)
                StackedAvatarsView(
                    avatarUrls: [nil, nil, nil],
                    size: 20,
                    border: 0
                )
            }
            VStack {
                StackedAvatarsView(avatarUrls: [])
                StackedAvatarsView(avatarUrls: [nil])
                StackedAvatarsView(avatarUrls: [nil, nil])
                StackedAvatarsView(avatarUrls: [], size: 20, border: 0)
                StackedAvatarsView(avatarUrls: [nil], size: 20, border: 0)
                StackedAvatarsView(
                    avatarUrls: [nil, nil],
                    size: 20,
                    border: 0
                )
            }
            .preferredColorScheme(.dark)
        }
        .padding(.horizontal)
        .padding(.vertical, 0)
        .background(Color.previewBg)
    }
}
