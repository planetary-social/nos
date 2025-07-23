// ABOUTME: Wallet balance display for the side menu
// ABOUTME: Shows total balance and provides quick access to wallet management

import SwiftUI
import Dependencies

struct WalletBalanceRow: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(CurrentUser.self) private var currentUser
    @EnvironmentObject private var router: Router
    
    @State private var balance: Int = 0
    @State private var hasWallet = false
    @State private var isLoading = true
    
    private var walletService: CashuWalletService {
        CashuWalletService(context: viewContext)
    }
    
    var body: some View {
        if hasWallet {
            Button {
                router.sideMenuPath.append(SideMenu.Destination.wallet)
            } label: {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient.diagonalAccent)
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "wallet.pass.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Cashu Wallet")
                            .font(.clarity(.semibold, textStyle: .body))
                            .foregroundColor(.primaryTxt)
                        
                        if isLoading {
                            Text("Loading...")
                                .font(.clarity(.regular, textStyle: .caption))
                                .foregroundColor(.secondaryTxt)
                        } else {
                            HStack(spacing: 4) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.orange)
                                
                                Text("\(balance) sats")
                                    .font(.clarity(.medium, textStyle: .caption))
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondaryTxt)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
        .task {
            await loadWalletBalance()
        }
    }
    
    private func loadWalletBalance() async {
        guard let author = currentUser.author else { return }
        
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
            print("Failed to load wallet balance: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}