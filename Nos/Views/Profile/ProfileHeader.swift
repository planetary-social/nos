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
                                MacadamiaWalletButton()
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

// Wallet button that directly launches the Macadamia wallet
struct MacadamiaWalletButton: View {
    @State private var showingWallet = false
    
    var body: some View {
        Button {
            showingWallet = true
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
            MacadamiaWalletLauncher()
        }
    }
}

// Launcher for the actual Macadamia wallet
struct MacadamiaWalletLauncher: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Launching Macadamia Wallet...")
                    .font(.headline)
                    .padding()
                
                ProgressView()
                    .padding()
            }
            .onAppear {
                launchMacadamiaWallet()
            }
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
    
    private func launchMacadamiaWallet() {
        // Delay to make the UI visible
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Launch Macadamia using FileManager to check if it exists
            let macadamiaPath = "/Users/rabble/code/nostr/macadamia"
            
            if FileManager.default.fileExists(atPath: macadamiaPath) {
                // Open the Macadamia app directly using a URL scheme
                // This would typically be a specific URL scheme registered by the app
                if let url = URL(string: "file:///Users/rabble/code/nostr/macadamia/macadamia.xcodeproj") {
                    UIApplication.shared.open(url, options: [:]) { success in
                        if success {
                            print("Successfully opened Macadamia")
                        } else {
                            print("Failed to open Macadamia")
                            
                            // Alternative approach: use the shell to open the app
                            let process = Process()
                            process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
                            process.arguments = [macadamiaPath]
                            
                            do {
                                try process.run()
                            } catch {
                                print("Error launching Macadamia: \(error)")
                            }
                        }
                        
                        // Close our sheet after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            dismiss()
                        }
                    }
                }
            } else {
                print("Macadamia wallet not found at \(macadamiaPath)")
                
                // Show an error message or fall back to our mock implementation
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    dismiss()
                }
            }
        }
    }
}