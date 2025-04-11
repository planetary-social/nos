import SwiftUI
import CoreData
import Logger
import Dependencies

struct ProfileHeader: View {
    @ObservedObject var author: Author
    @Environment(CurrentUser.self) private var currentUser

    @Binding private var selectedTab: ProfileFeedType
    @State private var showingBio = false

    private let followsRequest: FetchRequest<Follow>
    private var followsResult: FetchedResults<Follow> { followsRequest.wrappedValue }

    private let followersRequest: FetchRequest<Follow>
    private var followersResult: FetchedResults<Follow> { followersRequest.wrappedValue }
    
    private var followers: Followed {
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
    
    private var shouldShowWebsite: Bool {
        if let website = author.website {
            return website.isEmpty == false
        }
        return false
    }
    
    private var shouldShowPronouns: Bool {
        if let pronouns = author.pronouns {
            return pronouns.isEmpty == false
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

    private var divider: some View {
        Divider()
            .overlay(Color.profileDivider)
            .shadow(
                color: .profileDividerShadow,
                radius: 0,
                x: 0,
                y: 1
            )
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
                        // Name
                        Button {
                            showingBio = true
                        } label: {
                            Text(author.safeName)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .font(.title3.weight(.bold))
                                .foregroundColor(Color.primaryTxt)
                                .padding(.top, 10)
                        }

                        // NIP-05
                        if author.hasNIP05 {
                            Button {
                                showingBio = true
                            } label: {
                                NIP05View(author: author)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .font(.footnote)
                            }
                            .padding(.top, 3)
                        } else if let npub = author.npubString {
                            Button {
                                showingBio = true
                            } label: {
                                Text("@\(npub.prefix(10).appending("..."))")
                                    .foregroundStyle(Color.secondaryTxt)
                                    .font(.footnote)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .textSelection(.enabled)
                            }
                        }

                        // ActivityPub
                        if author.hasMostrNIP05 {
                            Button {
                                showingBio = true
                            } label: {
                                ActivityPubBadgeView(author: author)
                                    .padding(.top, 5)
                            }
                        }

                        Spacer(minLength: 0)
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
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 18)
                    .padding(.bottom, 9)
                }

                divider
                    .padding(.top, shouldShowBio ? 0 : 16)

                if let first = knownFollowers[safe: 0]?.source {
                    Button {
                        router.push(
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
                    .padding(.top, 5)
                }

                HStack(spacing: 0) {
                    if let currentUser = currentUser.author {
                        if author != currentUser {
                            FollowButton(
                                currentUserAuthor: currentUser,
                                author: author,
                                shouldDisplayIcon: true,
                                shouldFillHorizontalSpace: true
                            )
                        } else {
                            HStack(spacing: 10) {
                                ActionButton(
                                    "editProfile",
                                    font: .clarity(.bold, textStyle: .subheadline),
                                    depthEffectColor: .actionSecondaryDepthEffect,
                                    backgroundGradient: LinearGradient.verticalAccentSecondary,
                                    shouldFillHorizontalSpace: true
                                ) {
                                    router.push(EditProfileDestination(profile: author))
                                }
                                
                                // Wallet Button
                                WalletButtonPlaceholder()
                            }
                        }
                    }

                    ProfileSocialStatsView(
                        author: author,
                        followsResult: followsResult
                    )
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 0)
                .frame(maxWidth: .infinity)

                divider
                
                NosSegmentedPicker(
                    items: [ProfileFeedType.notes, ProfileFeedType.activity],
                    selectedItem: $selectedTab
                )
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
                    .nosNavigationBar("profileTitle")
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

// Wallet button that presents the wallet view
struct WalletButtonPlaceholder: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingWallet = false
    @EnvironmentObject private var router: Router
    
    var body: some View {
        Button {
            presentWallet()
        } label: {
            ZStack {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 44, height: 44)
                
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.purple) // Use a color from app's gradient
            }
        }
        .sheet(isPresented: $showingWallet) {
            // Present the WalletView directly, creating a simple wrapper
            WalletSheetWrapper()
                .preferredColorScheme(colorScheme)
        }
        .onAppear {
            // Listen for wallet open notifications
            NotificationCenter.default.addObserver(
                forName: Notification.Name("OpenWalletView"),
                object: nil,
                queue: .main
            ) { _ in
                showingWallet = true
            }
        }
    }
    
    private func presentWallet() {
        showingWallet = true
    }
}

// Simple wrapper around the wallet view to handle presentation
struct WalletSheetWrapper: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Dependency(\.walletManager) private var walletManager
    
    var body: some View {
        NavigationStack {
            VStack {
                // Check if wallet is initialized (temporary condition)
                if false {
                    walletContent
                } else {
                    noWalletView
                }
            }
            .navigationTitle("Cashu Wallet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                    }
                }
            }
        }
    }
    
    // Main wallet content view
    private var walletContent: some View {
        VStack(spacing: 8) {
            // Balance card
            VStack {
                Text("Balance")
                    .font(.clarity(.regular, textStyle: .subheadline))
                    .foregroundColor(.gray)
                
                Text("0 sats")
                    .font(.clarity(.bold, textStyle: .title))
                    .foregroundColor(.black)
                
                HStack {
                    Text("≈ $0.00")
                        .font(.clarity(.regular, textStyle: .caption))
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(20)
            
            // Tabs and actions
            VStack {
                HStack {
                    tabButton(title: "Balance", icon: "wallet.pass.fill", selected: true)
                    tabButton(title: "History", icon: "arrow.left.arrow.right", selected: false)
                    tabButton(title: "Settings", icon: "gear", selected: false)
                }
                .padding(.vertical)
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 16) {
                    actionButton(title: "Send", icon: "arrow.up")
                    actionButton(title: "Receive", icon: "arrow.down")
                    actionButton(title: "Mint", icon: "plus")
                    actionButton(title: "Pay", icon: "bolt")
                }
                .padding(.vertical)
            }
        }
        .padding()
    }
    
    // Wallet creation view
    private var noWalletView: some View {
        VStack(spacing: 24) {
            Image(systemName: "wallet.pass.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
                .padding(.bottom, 16)
            
            Text("No Cashu Wallet")
                .font(.clarity(.bold, textStyle: .title2))
                .foregroundColor(.primaryTxt)
            
            Text("Create or restore a Cashu wallet to start using Ecash in Nos")
                .font(.clarity(.regular, textStyle: .body))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondaryTxt)
                .padding(.horizontal)
            
            Button {
                // Initialize wallet (just dismiss for now)
                dismiss()
            } label: {
                Text("Create New Wallet")
                    .font(.clarity(.bold, textStyle: .body))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    // Helper for tab buttons
    private func tabButton(title: String, icon: String, selected: Bool) -> some View {
        Button {
            // Tab selection would be implemented here
        } label: {
            VStack {
                Image(systemName: icon)
                    .font(.system(size: 22))
                
                Text(title)
                    .font(.clarity(.medium, textStyle: .caption))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundColor(selected ? Color.purple : .gray)
            .background(
                selected ? Color.gray.opacity(0.1).cornerRadius(10) : nil
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Helper for action buttons
    private func actionButton(title: String, icon: String) -> some View {
        Button {
            // Action would be implemented here
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Circle())
                
                Text(title)
                    .font(.clarity(.medium, textStyle: .caption))
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}