// ABOUTME: Wallet balance and info display for user's own profile
// ABOUTME: Shows ecash balance and quick access to wallet management

import SwiftUI
import Dependencies

struct ProfileWalletView: View {
    let author: Author
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var router: Router
    @State private var balance: Int = 0
    @State private var hasWallet = false
    @State private var isLoading = true
    @State private var showWalletManagement = false
    
    private var walletService: CashuWalletService {
        CashuWalletService(context: viewContext)
    }
    
    var body: some View {
        if hasWallet {
            Button {
                showWalletManagement = true
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient.diagonalAccent)
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "wallet.pass.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Cashu Wallet")
                            .font(.clarity(.semibold, textStyle: .body))
                            .foregroundColor(.primaryTxt)
                        
                        if isLoading {
                            HStack(spacing: 4) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Loading balance...")
                                    .font(.clarity(.regular, textStyle: .caption))
                                    .foregroundColor(.secondaryTxt)
                            }
                        } else {
                            HStack(spacing: 6) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.orange)
                                
                                Text("\(balance) sats")
                                    .font(.clarity(.bold, textStyle: .headline))
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondaryTxt)
                }
                .padding()
                .background(Color.backgroundSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal)
            .padding(.vertical, 8)
            .sheet(isPresented: $showWalletManagement) {
                if let wallet = loadWallet() {
                    NavigationStack {
                        WalletManagementView(wallet: wallet)
                    }
                }
            }
        }
        .task {
            await loadWalletInfo()
        }
    }
    
    private func loadWalletInfo() async {
        do {
            let wallets = try await walletService.loadWallets(for: author)
            
            if let firstWallet = wallets.first {
                let totalBalance = try await walletService.getBalance(
                    for: firstWallet,
                    author: author
                )
                
                await MainActor.run {
                    self.hasWallet = true
                    self.balance = totalBalance
                    self.isLoading = false
                }
            } else {
                await MainActor.run {
                    self.hasWallet = false
                    self.isLoading = false
                }
            }
        } catch {
            print("Failed to load wallet info: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    private func loadWallet() -> CashuWallet? {
        let request = NSFetchRequest<Event>(entityName: "Event")
        request.predicate = NSPredicate(
            format: "author == %@ AND kind == %d",
            author,
            EventKind.cashuWallet.rawValue
        )
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        request.fetchLimit = 1
        
        do {
            let walletEvents = try viewContext.fetch(request)
            if let event = walletEvents.first,
               let tags = event.allTags as? [[String]] {
                
                var name = "My Wallet"
                var mintURL = ""
                
                for tag in tags {
                    if tag.count >= 2 {
                        switch tag[0] {
                        case "name":
                            name = tag[1]
                        case "mint":
                            if mintURL.isEmpty {
                                mintURL = tag[1]
                            }
                        default:
                            break
                        }
                    }
                }
                
                if !mintURL.isEmpty {
                    return CashuWallet(name: name, mintURL: mintURL)
                }
            }
        } catch {
            print("Failed to load wallet: \(error)")
        }
        
        return nil
    }
}