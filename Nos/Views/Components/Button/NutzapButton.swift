// ABOUTME: Button component for sending nutzaps (ecash payments) to notes
// ABOUTME: Shows nutzap count and handles nutzap sending flow

import Dependencies
import SwiftUI

struct NutzapButton: View {
    
    let note: Event
    
    /// Indicates whether the number of nutzaps is displayed
    let showsCount: Bool
    
    @FetchRequest private var nutzaps: FetchedResults<Event>
    
    @State private var showNutzapSheet = false
    @State private var hasWallet = false
    @State private var recipientAcceptsNutzaps = false
    
    @Environment(CurrentUser.self) private var currentUser
    @Environment(\.managedObjectContext) private var viewContext
    @ObservationIgnored @Dependency(\.analytics) private var analytics
    @ObservationIgnored @Dependency(\.persistenceController) private var persistenceController
    
    private var walletService: CashuWalletService {
        CashuWalletService(context: viewContext)
    }
    
    private var nutzapService: NutzapService {
        NutzapService(context: viewContext, walletService: walletService)
    }
    
    /// Initializes a NutzapButton object
    ///
    /// - Parameter note: The event associated with this Nutzap button
    /// - Parameter showsCount: Whether the number of nutzaps is displayed. Defaults to `true`
    init(note: Event, showsCount: Bool = true) {
        self.note = note
        self.showsCount = showsCount
        if let noteID = note.identifier {
            _nutzaps = FetchRequest(
                fetchRequest: Event.nutzaps(noteID: noteID),
                animation: .default
            )
        } else {
            _nutzaps = FetchRequest(fetchRequest: Event.emptyRequest())
        }
    }
    
    var nutzapCount: Int {
        nutzaps
            .compactMap { nutzap in
                guard let tags = nutzap.allTags as? [[String]] else { return nil }
                
                // Check if this nutzap references our note
                let referencesNote = tags.contains { tag in
                    tag.count >= 2 && tag[0] == "e" && tag[1] == note.identifier
                }
                
                if referencesNote {
                    // Extract amount
                    for tag in tags {
                        if tag.count >= 2 && tag[0] == "amount", let amount = Int(tag[1]) {
                            return amount
                        }
                    }
                }
                return nil
            }
            .reduce(0, +)
    }
    
    var buttonLabel: some View {
        HStack(spacing: 4) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(recipientAcceptsNutzaps ? .orange : .secondaryTxt)
            
            if showsCount, nutzapCount > 0 {
                Text(formatSats(nutzapCount))
                    .font(.clarity(.medium, textStyle: .subheadline))
                    .foregroundColor(.secondaryTxt)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
    }
    
    var body: some View {
        Button {
            if hasWallet && recipientAcceptsNutzaps {
                showNutzapSheet = true
                analytics.tappedNutzap()
            }
        } label: {
            buttonLabel
        }
        .disabled(!hasWallet || !recipientAcceptsNutzaps)
        .opacity((!hasWallet || !recipientAcceptsNutzaps) ? 0.5 : 1.0)
        .task {
            await checkWalletAndRecipient()
        }
        .sheet(isPresented: $showNutzapSheet) {
            if let author = note.author {
                NutzapSendingSheet(
                    recipient: author,
                    note: note,
                    onComplete: { amount in
                        // Nutzap sent successfully
                        analytics.sentNutzap(amount: amount)
                    }
                )
            }
        }
    }
    
    private func checkWalletAndRecipient() async {
        // Check if current user has a wallet
        if let currentAuthor = currentUser.author {
            let wallets = try? await walletService.loadWallets(for: currentAuthor)
            hasWallet = !(wallets?.isEmpty ?? true)
        }
        
        // Check if recipient accepts nutzaps
        if let recipientPubkey = note.author?.hexadecimalPublicKey {
            // For now, check if they have any nutzap info events
            // In production, would check for specific mint compatibility
            let request = NSFetchRequest<Event>(entityName: "Event")
            request.predicate = NSPredicate(
                format: "author.hexadecimalPublicKey == %@ AND kind == %d",
                recipientPubkey,
                EventKind.nutzapInfo.rawValue
            )
            request.fetchLimit = 1
            
            let nutzapInfoEvents = try? viewContext.fetch(request)
            recipientAcceptsNutzaps = !(nutzapInfoEvents?.isEmpty ?? true)
        }
    }
    
    private func formatSats(_ amount: Int) -> String {
        if amount >= 1000 {
            return String(format: "%.1fk", Double(amount) / 1000.0)
        }
        return String(amount)
    }
}

// Extension to add nutzap fetching to Event
extension Event {
    static func nutzaps(noteID: String) -> NSFetchRequest<Event> {
        let request = NSFetchRequest<Event>(entityName: "Event")
        request.predicate = NSPredicate(format: "kind == %d", EventKind.nutzap.rawValue)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        return request
    }
}
