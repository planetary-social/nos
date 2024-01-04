//
//  KnownFollowersView.swift
//  Nos
//
//  Created by Rabble on 10/10/23.
//

import Foundation
import SwiftUI

/// Shows a list of followers of the given author that the logged in user might know. This helps the user avoid
/// impersonation attacks by making sure they choose the right person to follow, mention, message, etc. 
struct KnownFollowersView: View {
    
    @ObservedObject var author: Author
    @Environment(CurrentUser.self) private var currentUser
    
    var followersRequest: FetchRequest<Follow>
    var followersResult: FetchedResults<Follow> { followersRequest.wrappedValue }
    
    var followers: Followed {
        followersResult.map { $0 }
    }
    
    var knownFollowers: [Follow] {
        followers.filter {
            guard let source = $0.source else {
                return false
            }
            return source.hasHumanFriendlyName == true &&
            source != author &&
            source != currentUser.author &&
            currentUser.isFollowing(author: source)
        }
    }
    
    var avatarURLs: [URL?] {
        knownFollowers.prefix(3).map { $0.source?.profilePhotoURL }
    }
    
    var followText: LocalizedStringKey {
        switch avatarURLs.count {
        case 1:
            guard let name = knownFollowers[safe: 0]?.source?.safeName else {
                fallthrough
            }
            return LocalizedStringKey(String(localized: LocalizedStringResource.localizable.followedByOne(name)))
        case 2:
            guard let firstName = knownFollowers[safe: 0]?.source?.safeName,
                let secondName = knownFollowers[safe: 1]?.source?.safeName else {
                fallthrough
            }
            return LocalizedStringKey(
                String(localized: LocalizedStringResource.localizable.followedByTwo(firstName, secondName))
            )
        case 3:
            guard let firstName = knownFollowers[safe: 0]?.source?.safeName,
                let secondName = knownFollowers[safe: 1]?.source?.safeName else {
                fallthrough
            }
            return LocalizedStringKey(
                String(
                    localized: LocalizedStringResource.localizable.followedByTwoAndMore(
                        firstName, secondName, followers.count - 2
                    )
                )
            )
        default:
            return ""
        }
    }
    
    init(author: Author) {
        self.author = author
        self.followersRequest = FetchRequest(fetchRequest: Follow.followsRequest(destination: [author]))
    }
    
    var body: some View {
        if knownFollowers.isEmpty == false {
            HStack {
                HStack {
                    StackedAvatarsView(avatarUrls: avatarURLs, border: 4)
                }
                .frame(width: 80)
                Text(followText)
                Spacer()
            }
            .foregroundColor(.secondaryTxt)
        } else {
            EmptyView()
        }
    }
}

#Preview {
    var previewData = PreviewData()
    
    return VStack {
        KnownFollowersView(author: previewData.alice)
        KnownFollowersView(author: previewData.bob) // should display nothing
    }
    .background(Color.appBg)
    .padding()
    .inject(previewData: previewData)
}
