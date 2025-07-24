// ABOUTME: Floating wallet balance widget for quick balance checking
// ABOUTME: Displays balance and provides tap access to wallet management

import SwiftUI
import Dependencies

struct WalletBalanceWidget: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(CurrentUser.self) private var currentUser
    @EnvironmentObject private var router: Router
    
    @State private var balance: Int = 0
    @State private var hasWallet = false
    @State private var isLoading = true
    @State private var showWalletManagement = false
    @State private var wallet: CashuWallet?
    
    private var walletService: CashuWalletService {
        CashuWalletService(context: viewContext)
    }
    
    var body: some View {
        if hasWallet {
            Button {
                showWalletManagement = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.orange)
                    
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Text("\(balance)")
                            .font(.clarity(.semibold, textStyle: .body))
                            .foregroundColor(.white)
                        
                        Text("sats")
                            .font(.clarity(.regular, textStyle: .caption))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(LinearGradient.diagonalAccent)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                )
            }
            .buttonStyle(ScaleButtonStyle())
            .sheet(isPresented: $showWalletManagement) {
                if let wallet = wallet {
                    NavigationStack {
                        WalletManagementView(wallet: wallet)
                    }
                }
            }
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
                    self.wallet = firstWallet
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

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// View modifier to add wallet widget overlay
struct WalletWidgetOverlay: ViewModifier {
    let showWidget: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topTrailing) {
                if showWidget {
                    WalletBalanceWidget()
                        .padding(.top, 8)
                        .padding(.trailing, 16)
                }
            }
    }
}

extension View {
    func walletWidget(show: Bool = true) -> some View {
        modifier(WalletWidgetOverlay(showWidget: show))
    }
}