import SwiftUI
import CoreData
import Logger

struct ProfileHeader: View {
    @ObservedObject var author: Author
    @Environment(CurrentUser.self) private var currentUser

    @Binding private var selectedTab: ProfileFeedType
    @State private var showingBio = false

    var followsRequest: FetchRequest<Follow>
    var followsResult: FetchedResults<Follow> { followsRequest.wrappedValue }

    var followersRequest: FetchRequest<Follow>
    var followersResult: FetchedResults<Follow> { followersRequest.wrappedValue }
    
    var followers: Followed {
        followersResult.map { $0 }
    }
    
    @EnvironmentObject private var router: Router

    init(author: Author, selectedTab: Binding<ProfileFeedType>) {
        self.author = author
        self.followsRequest = FetchRequest(fetchRequest: Follow.followsRequest(sources: [author]))
        self.followersRequest = FetchRequest(fetchRequest: Follow.followsRequest(destination: [author]))
        _selectedTab = selectedTab
    }

    private var shouldShowBio: Bool {
        if let about = author.about {
            return about.isEmpty == false
        }
        return false
    }

    private var knownFollowers: [Follow] {
        author.followers.filter {
            guard let source = $0.source else {
                return false
            }
            return source.hasHumanFriendlyName == true &&
                source != author &&
                (currentUser.isFollowing(author: source) || currentUser.isBeingFollowedBy(author: source))
        }
    }

    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                HStack(alignment: .top, spacing: 18) {
                    ZStack(alignment: .bottomTrailing) {
                        AvatarView(imageUrl: author.profilePhotoURL, size: 87)
                            .font(.body)
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 99)
                                    .stroke(LinearGradient.diagonalAccent, lineWidth: 3)
                            )
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Spacer()

                        Button {
                            showingBio = true
                        } label: {
                            Text(author.safeName)
                                .lineLimit(1)
                                .font(.clarity(.bold, textStyle: .title3).weight(.semibold))
                                .foregroundColor(Color.primaryTxt)
                        }

                        // NIP-05
                        Button {
                            showingBio = true
                        } label: {
                            NIP05View(author: author)
                                .lineLimit(1)
                        }
                        .padding(.top, 3)

                        // Universal name
                        UNSNameView(author: author)
                            
                        if author != currentUser.author, let currentUser = currentUser.author {
                            HStack {
                                FollowButton(currentUserAuthor: currentUser, author: author)
                                if author.muted {
                                    Text(.localizable.muted)
                                        .font(.subheadline)
                                        .foregroundColor(Color.secondaryTxt)
                                }
                            }
                            .padding(.top, 3)
                        }

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top)
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .topLeading)

                if shouldShowBio {
                    Button {
                        showingBio = true
                    } label: {
                        BioView(author: author)
                    }
                    .padding(.top, 18)
                }

                if let first = knownFollowers[safe: 0]?.source {
                    Button {
                        router.currentPath.wrappedValue.append(
                            FollowersDestination(
                                author: author,
                                followers: followersResult.compactMap { $0.source }
                            )
                        )
                    } label: {
                        ProfileKnownFollowersView(
                            first: first,
                            knownFollowers: knownFollowers,
                            followers: followers
                        )
                    }
                }

                ProfileSocialStatsView(
                    author: author,
                    followsResult: followsResult,
                    followersResult: followersResult
                )

                profileHeaderTab
            }
            .frame(maxWidth: 500)
        }
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.profileBgTop, Color.profileBgBottom],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .sheet(isPresented: $showingBio) {
            NavigationView {
                BioSheet(author: author)
                    .background(Color.bioBgGradientBottom)
                    .nosNavigationBar(title: .localizable.profile)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                showingBio = false
                            } label: {
                                Image.navIconDismiss
                            }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var profileHeaderTab: some View {
        HStack {
            Button {
                selectedTab = .notes
            } label: {
                HStack {
                    Spacer()
                    let color = selectedTab == .notes ? Color.primaryTxt : .secondaryTxt
                    Image.profilePosts
                        .renderingMode(.template)
                        .foregroundColor(color)
                    Text(.localizable.notes)
                        .foregroundColor(color)
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity)

            Button {
                selectedTab = .activity
            } label: {
                HStack {
                    Spacer()
                    let color = selectedTab == .activity ? Color.primaryTxt : .secondaryTxt
                    Image.profileFeed
                        .renderingMode(.template)
                        .foregroundColor(color)
                    Text(.localizable.activity)
                        .foregroundColor(color)
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
    }
}

#Preview {
    var previewData = PreviewData()
    
    return Group {
        // ProfileHeader(author: author)
        ProfileHeader(author: previewData.previewAuthor, selectedTab: .constant(.activity))
            .inject(previewData: previewData)
            .padding()
            .background(Color.previewBg)
    }
}

#Preview {
    var previewData = PreviewData()

    var author: Author {
        let previewContext = previewData.previewContext
        let author = Author(context: previewContext)
        author.hexadecimalPublicKey = KeyFixture.pubKeyHex
        author.add(relay: Relay(context: previewContext))
        author.name = "Sebastian Heit"
        author.nip05 = "chardot@nostr.fan"
        // author.uns = "chardot"
        author.about = "Go programmer working on Nos/Planetary. You can find me at various European events related to" +
        " Chaos Computer Club, the hacker community and free software."
        let first = Author(context: previewContext)
        first.name = "Craig Nichols"

        let second = Author(context: previewContext)
        second.name = "Justin Pool"

        let firstFollow = Follow(context: previewContext)
        firstFollow.source = first
        firstFollow.destination = author

        let secondFollow = Follow(context: previewContext)
        secondFollow.source = second
        secondFollow.destination = author

        author.addToFollowers(secondFollow)

        return author
    }
    
    return Group {
        ProfileHeader(author: author, selectedTab: .constant(.activity))
    }
    .inject(previewData: previewData)
    .previewDevice("iPhone SE (2nd generation)")
    .padding()
    .background(Color.previewBg)
}

#Preview("UNS") {
    var previewData = PreviewData()
    
    return Group {
        ProfileHeader(author: previewData.unsAuthor, selectedTab: .constant(.activity))
            .inject(previewData: previewData)
            .padding()
            .background(Color.previewBg)
    }
}
