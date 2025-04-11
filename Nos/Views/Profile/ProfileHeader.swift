import SwiftUI
import CoreData
import Logger
import Dependencies
import UIKit

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
                                WalletButton()
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

// Wallet button implementation with a direct link to the MacadamiaWalletView
struct WalletButton: View {
    @State private var showingWalletView = false
    @Environment(\.colorScheme) private var colorScheme
    @Dependency(\.walletManager) private var walletManager
    
    var body: some View {
        Button {
            showingWalletView = true
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
        .sheet(isPresented: $showingWalletView) {
            MacadamiaWalletView()
                .preferredColorScheme(colorScheme)
        }
    }
}

// Direct integration with the wallet manager from Macadamia
struct MacadamiaWalletView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Dependency(\.walletManager) private var walletManager
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            walletMainContent
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                }
        }
    }
    
    // Main content container
    private var walletMainContent: some View {
        VStack(spacing: 12) {
            balanceCard
            tabSelector
            tabContent
            Spacer()
        }
    }
    
    // Balance card at the top
    private var balanceCard: some View {
        VStack {
            Text("Cashu Wallet")
                .font(.title2.bold())
                .padding(.top)
            
            Text("Balance: 0 sats")
                .font(.title3)
                .padding(.vertical, 4)
            
            Text("≈ $0.00")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    // Tab selector
    private var tabSelector: some View {
        HStack {
            ForEach(0..<3) { index in
                tabButton(index: index)
            }
        }
        .padding(.horizontal)
    }
    
    // Individual tab button
    private func tabButton(index: Int) -> some View {
        let titles = ["Wallet", "Activity", "Settings"]
        
        return Button {
            selectedTab = index
        } label: {
            VStack {
                Image(systemName: tabIcon(for: index))
                    .font(.system(size: 22))
                Text(titles[index])
                    .font(.caption)
            }
            .foregroundColor(selectedTab == index ? Color.purple : .gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                Group {
                    if selectedTab == index {
                        RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1))
                    } else {
                        Color.clear
                    }
                }
            )
        }
    }
    
    // Tab content area
    private var tabContent: some View {
        Group {
            if selectedTab == 0 {
                walletTabContent
            } else if selectedTab == 1 {
                activityTabContent
            } else {
                settingsTabContent
            }
        }
    }
    
    // Wallet tab content
    private var walletTabContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                createWalletButton
                actionButtonsRow
            }
            .padding(.vertical)
        }
    }
    
    // Create wallet button
    private var createWalletButton: some View {
        Button {
            // This would normally trigger wallet creation
            print("Create wallet tapped")
        } label: {
            Text("Create Wallet")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
        }
        .padding(.horizontal)
    }
    
    // Action buttons row
    private var actionButtonsRow: some View {
        HStack(spacing: 16) {
            actionButton(title: "Send", icon: "arrow.up")
            actionButton(title: "Receive", icon: "arrow.down")
            actionButton(title: "Mint", icon: "plus")
            actionButton(title: "Pay", icon: "bolt")
        }
        .padding(.horizontal)
    }
    
    // Activity tab content
    private var activityTabContent: some View {
        VStack {
            Image(systemName: "clock")
                .font(.system(size: 40))
                .foregroundColor(.gray)
                .padding()
            
            Text("No activity yet")
                .font(.headline)
            
            Text("Your transaction history will appear here")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding()
        }
        .frame(maxHeight: .infinity)
    }
    
    // Settings tab content
    private var settingsTabContent: some View {
        List {
            Section("Wallet") {
                settingRow(icon: "key", title: "Backup Keys")
                settingRow(icon: "arrow.clockwise", title: "Restore Wallet")
                settingRow(icon: "trash", title: "Delete Wallet")
            }
            
            Section("Preferences") {
                settingRow(icon: "bell", title: "Notifications")
                settingRow(icon: "lock", title: "Privacy")
            }
            
            Section("About") {
                settingRow(icon: "info.circle", title: "About Cashu")
                settingRow(icon: "questionmark.circle", title: "Help")
            }
        }
    }
    
    // Helper for tab icons
    private func tabIcon(for index: Int) -> String {
        switch index {
        case 0: return "wallet.pass.fill"
        case 1: return "clock"
        case 2: return "gear"
        default: return "questionmark"
        }
    }
    
    // Helper for action buttons
    private func actionButton(title: String, icon: String) -> some View {
        Button {
            // Action would be implemented here
            print("\(title) tapped")
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
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // Helper for settings rows
    private func settingRow(icon: String, title: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 24)
            
            Text(title)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}