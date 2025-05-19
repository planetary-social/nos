import SwiftUI
import CoreData
import Logger
import Dependencies
import UIKit
import Foundation

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
                                EmbeddedWalletButton()
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

// MARK: - Embedded Wallet Implementation

// A mint represents a Cashu mint server
struct Mint: Identifiable {
    let id = UUID()
    let name: String
    let url: URL
    var balance: Int = 0
}

// A wallet transaction
struct WalletTransaction: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Int
    let type: TransactionType
    let memo: String?
    
    enum TransactionType: String {
        case send, receive, mint, melt
        
        var iconName: String {
            switch self {
            case .send: return "arrow.up"
            case .receive: return "arrow.down"
            case .mint: return "plus"
            case .melt: return "bolt"
            }
        }
    }
}

// Wallet button that opens the embedded wallet
struct EmbeddedWalletButton: View {
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
                    .foregroundColor(Color.purple)
            }
        }
        .sheet(isPresented: $showingWallet) {
            NavigationStack {
                EmbeddedWalletView()
                    .navigationTitle("Cashu Wallet")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                showingWallet = false
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                    }
            }
        }
    }
}

// Main wallet view with embedded functionality
struct EmbeddedWalletView: View {
    // Wallet state
    @State private var walletInitialized = false
    @State private var balance = 0
    @State private var mints: [Mint] = []
    @State private var transactions: [WalletTransaction] = []
    @State private var selectedTab = 0
    
    // Sheet states
    @State private var showingCreateWallet = false
    @State private var showingSendView = false
    @State private var showingReceiveView = false
    @State private var showingMintView = false
    @State private var showingMeltView = false
    @State private var showingAddMintView = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Balance card
            balanceCard
            
            // Tab selector
            HStack {
                ForEach(0..<3) { index in
                    tabButton(index: index)
                }
            }
            .padding()
            
            // Content based on selected tab
            if selectedTab == 0 {
                walletTab
            } else if selectedTab == 1 {
                transactionsTab
            } else {
                settingsTab
            }
        }
        .alert("Create Wallet", isPresented: $showingCreateWallet) {
            Button("Create", action: createWallet)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Create a new wallet to store and spend Bitcoin using Cashu?")
        }
        .sheet(isPresented: $showingSendView) {
            NavigationStack {
                SendTokensView()
            }
        }
        .sheet(isPresented: $showingReceiveView) {
            NavigationStack {
                ReceiveTokensView()
            }
        }
        .sheet(isPresented: $showingMintView) {
            NavigationStack {
                MintTokensView()
            }
        }
        .sheet(isPresented: $showingMeltView) {
            NavigationStack {
                MeltTokensView()
            }
        }
        .sheet(isPresented: $showingAddMintView) {
            NavigationStack {
                AddMintView(onAdd: addMint)
            }
        }
        .onAppear {
            // Check for wallet
            checkForWallet()
        }
    }
    
    // Balance display at the top
    private var balanceCard: some View {
        VStack(spacing: 4) {
            Text("Balance")
                .font(.footnote)
                .foregroundColor(.gray)
            
            Text("\(balance) sats")
                .font(.title)
                .bold()
            
            Text("≈ $\(Double(balance) / 100000, specifier: "%.2f")")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
    }
    
    // Tab button
    private func tabButton(index: Int) -> some View {
        let titles = ["Wallet", "Transactions", "Settings"]
        let icons = ["wallet.pass.fill", "arrow.left.arrow.right", "gear"]
        
        return Button {
            selectedTab = index
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icons[index])
                    .font(.system(size: 18))
                Text(titles[index])
                    .font(.caption)
            }
            .foregroundColor(selectedTab == index ? .purple : .gray)
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
    
    // Wallet tab content
    private var walletTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                if !walletInitialized {
                    // Create wallet prompt
                    VStack(spacing: 16) {
                        Image(systemName: "wallet.pass.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.purple)
                            .padding()
                        
                        Text("No Wallet Found")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Create a wallet to start using Cashu")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        
                        Button {
                            showingCreateWallet = true
                        } label: {
                            Text("Create Wallet")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.top)
                    }
                    .padding()
                } else {
                    // Mints section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Your Mints")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button {
                                showingAddMintView = true
                            } label: {
                                Label("Add", systemImage: "plus")
                                    .font(.caption)
                                    .foregroundColor(.purple)
                            }
                        }
                        
                        if mints.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "server.rack")
                                    .font(.system(size: 30))
                                    .foregroundColor(.gray)
                                
                                Text("No mints added")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                Button {
                                    showingAddMintView = true
                                } label: {
                                    Text("Add Mint")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.purple)
                                        .cornerRadius(8)
                                }
                                .padding(.top, 4)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(12)
                        } else {
                            ForEach(mints) { mint in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(mint.name)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        Text(mint.url.host ?? mint.url.absoluteString)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("\(mint.balance) sats")
                                        .font(.callout)
                                        .fontWeight(.semibold)
                                }
                                .padding()
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                    
                    // Action buttons
                    HStack(spacing: 16) {
                        actionButton(title: "Send", icon: "arrow.up") {
                            showingSendView = true
                        }
                        
                        actionButton(title: "Receive", icon: "arrow.down") {
                            showingReceiveView = true
                        }
                        
                        actionButton(title: "Mint", icon: "plus") {
                            showingMintView = true
                        }
                        
                        actionButton(title: "Pay", icon: "bolt") {
                            showingMeltView = true
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    // Transactions tab content
    private var transactionsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Transaction History")
                    .font(.headline)
                    .padding(.horizontal)
                
                if transactions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                            .padding()
                        
                        Text("No transactions yet")
                            .font(.headline)
                        
                        Text("Your transaction history will appear here")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                } else {
                    ForEach(transactions) { transaction in
                        transactionRow(transaction)
                    }
                }
            }
            .padding(.top)
        }
    }
    
    // Settings tab content
    private var settingsTab: some View {
        List {
            Section("Wallet") {
                Button {
                    // Backup wallet
                } label: {
                    settingRow(icon: "key", title: "Backup Keys")
                }
                
                Button {
                    // Restore wallet
                } label: {
                    settingRow(icon: "arrow.clockwise", title: "Restore Wallet")
                }
                
                Button {
                    // Delete wallet
                } label: {
                    settingRow(icon: "trash", title: "Delete Wallet")
                }
            }
            
            Section("Preferences") {
                Button {
                    // Currency settings
                } label: {
                    settingRow(icon: "dollarsign.circle", title: "Currency Display")
                }
                
                Button {
                    // Default mint
                } label: {
                    settingRow(icon: "server.rack", title: "Default Mint")
                }
            }
            
            Section("About") {
                Button {
                    // About Cashu
                } label: {
                    settingRow(icon: "info.circle", title: "What is Cashu?")
                }
                
                Button {
                    // Privacy policy
                } label: {
                    settingRow(icon: "eye.slash", title: "Privacy Policy")
                }
            }
        }
    }
    
    // Transaction row view
    private func transactionRow(_ transaction: WalletTransaction) -> some View {
        HStack(spacing: 16) {
            Image(systemName: transaction.type.iconName)
                .font(.system(size: 20))
                .foregroundColor(transactionColor(for: transaction.type))
                .frame(width: 40, height: 40)
                .background(transactionColor(for: transaction.type).opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.type.rawValue.capitalized)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(transaction.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if let memo = transaction.memo {
                    Text(memo)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Text(transactionAmountText(for: transaction))
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundColor(transactionAmountColor(for: transaction.type))
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // Helper for setting rows
    private func settingRow(icon: String, title: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
    
    // Helper for action buttons
    private func actionButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
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
    
    // Helper for transaction colors
    private func transactionColor(for type: WalletTransaction.TransactionType) -> Color {
        switch type {
        case .send: return .orange
        case .receive: return .green
        case .mint: return .purple
        case .melt: return .blue
        }
    }
    
    // Helper for transaction amount text
    private func transactionAmountText(for transaction: WalletTransaction) -> String {
        let prefix = transaction.type == .receive || transaction.type == .mint ? "+" : "-"
        return "\(prefix)\(transaction.amount) sats"
    }
    
    // Helper for transaction amount color
    private func transactionAmountColor(for type: WalletTransaction.TransactionType) -> Color {
        switch type {
        case .receive, .mint: return .green
        default: return .primary
        }
    }
    
    // MARK: - Wallet Logic Functions
    
    private func checkForWallet() {
        // In a real implementation, we'd check for an existing wallet
        // For demo purposes, we'll set initialized to false initially
        walletInitialized = false
    }
    
    private func createWallet() {
        // Simulate wallet creation
        walletInitialized = true
        
        // Add a default mint
        if let url = URL(string: "https://legend.lnbits.com/cashu/api/v1/4gr9Xcmz3XEkUNwiBiQGoL") {
            let mint = Mint(name: "Legend", url: url, balance: 0)
            mints.append(mint)
        }
        
        // Simulate a welcome transaction
        let transaction = WalletTransaction(
            date: Date(),
            amount: 0,
            type: .mint,
            memo: "Wallet created"
        )
        transactions.append(transaction)
    }
    
    private func addMint(_ mint: Mint) {
        mints.append(mint)
    }
}

// MARK: - Transaction View Screens

struct SendTokensView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var amount = ""
    @State private var recipient = ""
    @State private var memo = ""
    
    var body: some View {
        VStack {
            Text("Send Cashu Tokens")
                .font(.title2)
                .fontWeight(.bold)
                .padding()
            
            Form {
                Section("Amount") {
                    TextField("Amount (sats)", text: $amount)
                        .keyboardType(.numberPad)
                }
                
                Section("Recipient") {
                    TextField("Paste token or scan QR", text: $recipient)
                }
                
                Section("Memo (optional)") {
                    TextField("Add a note", text: $memo)
                }
            }
            
            Button {
                // Send tokens logic would go here
                dismiss()
            } label: {
                Text("Send")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
            .padding()
            .disabled(amount.isEmpty || recipient.isEmpty)
        }
        .navigationTitle("Send")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
}

struct ReceiveTokensView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var tokenText = "Example Cashu Token"
    
    var body: some View {
        VStack {
            Text("Receive Cashu Tokens")
                .font(.title2)
                .fontWeight(.bold)
                .padding()
            
            // QR code placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(radius: 2)
                    .frame(width: 200, height: 200)
                
                Image(systemName: "qrcode")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .foregroundColor(.black)
            }
            .padding()
            
            VStack {
                Text("Token")
                    .font(.headline)
                
                Text(tokenText)
                    .font(.subheadline)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding()
            
            HStack {
                Button {
                    // Copy to clipboard logic
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                }
                
                Button {
                    // Share token logic
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            .padding()
            
            Spacer()
        }
        .navigationTitle("Receive")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

struct MintTokensView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var amount = ""
    @State private var selectedMint: UUID?
    
    var body: some View {
        VStack {
            Text("Mint New Tokens")
                .font(.title2)
                .fontWeight(.bold)
                .padding()
            
            Form {
                Section("Amount") {
                    TextField("Amount (sats)", text: $amount)
                        .keyboardType(.numberPad)
                }
                
                Section("Mint") {
                    Text("Legend Mint")
                        .font(.subheadline)
                }
            }
            
            VStack(spacing: 16) {
                Button {
                    // Generate invoice logic
                } label: {
                    Text("Generate Lightning Invoice")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
                
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .font(.headline)
                        .foregroundColor(.purple)
                }
            }
            .padding()
        }
        .navigationTitle("Mint")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MeltTokensView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var invoice = ""
    
    var body: some View {
        VStack {
            Text("Pay Lightning Invoice")
                .font(.title2)
                .fontWeight(.bold)
                .padding()
            
            Form {
                Section("Lightning Invoice") {
                    TextField("Paste invoice or scan QR", text: $invoice)
                }
                
                Section("Amount") {
                    Text("Amount will be detected from invoice")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            }
            
            Button {
                // Pay invoice logic
                dismiss()
            } label: {
                Text("Pay Invoice")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
            .padding()
            .disabled(invoice.isEmpty)
        }
        .navigationTitle("Pay")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
}

struct AddMintView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var url = ""
    var onAdd: (Mint) -> Void
    
    var body: some View {
        VStack {
            Text("Add Mint")
                .font(.title2)
                .fontWeight(.bold)
                .padding()
            
            Form {
                Section("Mint Name") {
                    TextField("Name", text: $name)
                }
                
                Section("Mint URL") {
                    TextField("https://...", text: $url)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
            }
            
            Button {
                if let mintURL = URL(string: url) {
                    let mint = Mint(name: name.isEmpty ? "New Mint" : name, url: mintURL)
                    onAdd(mint)
                }
                dismiss()
            } label: {
                Text("Add Mint")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
            .padding()
            .disabled(url.isEmpty)
        }
        .navigationTitle("Add Mint")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
}