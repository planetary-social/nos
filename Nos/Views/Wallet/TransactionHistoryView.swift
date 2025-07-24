// ABOUTME: View showing nutzap transaction history with sent and received ecash
// ABOUTME: Displays transaction details including amounts, recipients, and timestamps

import SwiftUI
import Dependencies
import CoreData

struct TransactionHistoryView: View {
    let wallet: CashuWallet
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(CurrentUser.self) private var currentUser
    @Dependency(\.persistenceController) private var persistenceController
    
    @State private var sentNutzaps: [Event] = []
    @State private var receivedNutzaps: [Event] = []
    @State private var isLoading = true
    @State private var selectedTab: TransactionTab = .all
    
    private var walletService: CashuWalletService {
        CashuWalletService(context: viewContext)
    }
    
    private var nutzapService: NutzapService {
        NutzapService(context: viewContext, walletService: walletService)
    }
    
    enum TransactionTab: String, CaseIterable {
        case all = "All"
        case sent = "Sent"
        case received = "Received"
        
        var systemImage: String {
            switch self {
            case .all: return "arrow.left.arrow.right"
            case .sent: return "arrow.up.circle"
            case .received: return "arrow.down.circle"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            Picker("Transaction Type", selection: $selectedTab) {
                ForEach(TransactionTab.allCases, id: \.self) { tab in
                    Label(tab.rawValue, systemImage: tab.systemImage)
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            .background(Color.appBg)
            
            if isLoading {
                Spacer()
                ProgressView("Loading transactions...")
                    .tint(.primaryTxt)
                Spacer()
            } else if filteredTransactions.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredTransactions, id: \.identifier) { transaction in
                            TransactionRow(
                                transaction: transaction,
                                wallet: wallet,
                                isSent: sentNutzaps.contains(transaction)
                            )
                            
                            if transaction != filteredTransactions.last {
                                Divider()
                                    .background(Color.profileDivider)
                            }
                        }
                    }
                }
            }
        }
        .background(Color.appBg)
        .navigationTitle("Transaction History")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadTransactions()
        }
    }
    
    private var filteredTransactions: [Event] {
        let allTransactions: [Event]
        switch selectedTab {
        case .all:
            allTransactions = (sentNutzaps + receivedNutzaps)
        case .sent:
            allTransactions = sentNutzaps
        case .received:
            allTransactions = receivedNutzaps
        }
        
        return allTransactions.sorted { ($0.createdAt ?? Date.distantPast) > ($1.createdAt ?? Date.distantPast) }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: selectedTab == .sent ? "arrow.up.circle" : 
                              selectedTab == .received ? "arrow.down.circle" : 
                              "arrow.left.arrow.right.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondaryTxt)
            
            Text("No \(selectedTab == .all ? "transactions" : "\(selectedTab.rawValue.lowercased()) transactions") yet")
                .font(.title3)
                .foregroundColor(.primaryTxt)
            
            Text(selectedTab == .sent ? "Send nutzaps to other users" : 
                 selectedTab == .received ? "Receive nutzaps from other users" :
                 "Your nutzap transactions will appear here")
                .font(.body)
                .foregroundColor(.secondaryTxt)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    private func loadTransactions() async {
        guard let author = currentUser.author else { return }
        
        isLoading = true
        
        do {
            // Fetch sent nutzaps (where we are the author)
            let sent = try await fetchNutzaps(author: author, sent: true)
            
            // Fetch received nutzaps (where we are the recipient)
            let received = try await fetchNutzaps(author: author, sent: false)
            
            await MainActor.run {
                self.sentNutzaps = sent
                self.receivedNutzaps = received
                self.isLoading = false
            }
        } catch {
            print("Failed to load transactions: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    private func fetchNutzaps(author: Author, sent: Bool) async throws -> [Event] {
        let request = NSFetchRequest<Event>(entityName: "Event")
        
        if sent {
            // Fetch nutzaps sent by this author
            request.predicate = NSPredicate(
                format: "author == %@ AND kind == %d",
                author,
                EventKind.nutzap.rawValue
            )
        } else {
            // Fetch nutzaps received by this author (check p tag)
            request.predicate = NSPredicate(
                format: "kind == %d",
                EventKind.nutzap.rawValue
            )
        }
        
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        let events = try viewContext.fetch(request)
        
        if sent {
            return events
        } else {
            // Filter for events where we are the recipient
            let authorPubkey = author.hexadecimalPublicKey ?? ""
            return events.filter { event in
                guard let tags = event.allTags as? [[String]] else { return false }
                return tags.contains { tag in
                    tag.count >= 2 && tag[0] == "p" && tag[1] == authorPubkey
                }
            }
        }
    }
}

struct TransactionRow: View {
    let transaction: Event
    let wallet: CashuWallet
    let isSent: Bool
    
    @EnvironmentObject private var router: Router
    
    private var amount: Int {
        guard let tags = transaction.allTags as? [[String]] else { return 0 }
        let amountTag = tags.first { $0.count >= 2 && $0[0] == "amount" }
        return Int(amountTag?[1] ?? "0") ?? 0
    }
    
    private var recipientPubkey: String? {
        guard let tags = transaction.allTags as? [[String]] else { return nil }
        let pTag = tags.first { $0.count >= 2 && $0[0] == "p" }
        return pTag?[1]
    }
    
    private var comment: String? {
        guard let tags = transaction.allTags as? [[String]] else { return nil }
        let commentTag = tags.first { $0.count >= 2 && $0[0] == "comment" }
        return commentTag?[1]
    }
    
    private var mintURL: String? {
        guard let tags = transaction.allTags as? [[String]] else { return nil }
        let mintTag = tags.first { $0.count >= 2 && $0[0] == "u" }
        return mintTag?[1]
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Direction icon
            Image(systemName: isSent ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .font(.title2)
                .foregroundColor(isSent ? .red : .green)
            
            VStack(alignment: .leading, spacing: 4) {
                // Recipient/Sender
                HStack {
                    Text(isSent ? "To:" : "From:")
                        .font(.caption)
                        .foregroundColor(.secondaryTxt)
                    
                    if isSent, let recipientPubkey = recipientPubkey,
                       let author = Author.find(by: recipientPubkey, context: transaction.managedObjectContext!) {
                        Button {
                            router.push(author)
                        } label: {
                            Text(author.safeName)
                                .font(.body.weight(.medium))
                                .foregroundColor(.primaryTxt)
                                .lineLimit(1)
                        }
                    } else if !isSent, let author = transaction.author {
                        Button {
                            router.push(author)
                        } label: {
                            Text(author.safeName)
                                .font(.body.weight(.medium))
                                .foregroundColor(.primaryTxt)
                                .lineLimit(1)
                        }
                    } else {
                        Text("Unknown")
                            .font(.body)
                            .foregroundColor(.secondaryTxt)
                    }
                    
                    Spacer()
                }
                
                // Comment if present
                if let comment = comment, !comment.isEmpty {
                    Text(comment)
                        .font(.caption)
                        .foregroundColor(.primaryTxt)
                        .lineLimit(2)
                }
                
                // Timestamp and mint
                HStack {
                    if let createdAt = transaction.createdAt {
                        Text(createdAt.distanceString())
                            .font(.caption)
                            .foregroundColor(.secondaryTxt)
                    }
                    
                    if let mintURL = mintURL {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondaryTxt)
                        
                        Text(URL(string: mintURL)?.host ?? "Unknown mint")
                            .font(.caption)
                            .foregroundColor(.secondaryTxt)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // Amount
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(isSent ? "-" : "+")\(amount)")
                    .font(.headline)
                    .foregroundColor(isSent ? .red : .green)
                
                Text("sats")
                    .font(.caption)
                    .foregroundColor(.secondaryTxt)
            }
        }
        .padding()
    }
}