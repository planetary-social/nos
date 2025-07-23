// ABOUTME: Settings section for Cashu wallet configuration
// ABOUTME: Shows wallet balance, mint selection, and access to wallet management

import SwiftUI
import Dependencies

struct WalletSettingsSection: View {
    @Dependency(\.persistenceController) private var persistenceController
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(CurrentUser.self) private var currentUser
    
    @State private var wallet: CashuWallet?
    @State private var balance: Int = 0
    @State private var isLoadingBalance = false
    @State private var showWalletManagement = false
    @State private var showWalletOnboarding = false
    
    private var walletService: CashuWalletService {
        CashuWalletService(context: viewContext)
    }
    
    var body: some View {
        Section {
            if let wallet = wallet {
                // Wallet exists - show balance and management
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Cashu Wallet")
                            .font(.clarity(.semibold, textStyle: .body))
                            .foregroundColor(.primaryTxt)
                        
                        Text(wallet.name)
                            .font(.clarity(.regular, textStyle: .caption))
                            .foregroundColor(.secondaryTxt)
                    }
                    
                    Spacer()
                    
                    if isLoadingBalance {
                        ProgressView()
                            .tint(.primaryTxt)
                    } else {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(balance) sats")
                                .font(.clarity(.semibold, textStyle: .body))
                                .foregroundColor(.primaryTxt)
                            
                            Text("Balance")
                                .font(.clarity(.regular, textStyle: .caption))
                                .foregroundColor(.secondaryTxt)
                        }
                    }
                }
                .padding(.vertical, 8)
                .contentShape(Rectangle())
                .onTapGesture {
                    showWalletManagement = true
                }
                
                // Quick access to mint management
                HStack {
                    Text("Trusted Mints")
                        .font(.clarity(.regular, textStyle: .body))
                        .foregroundColor(.primaryTxt)
                    
                    Spacer()
                    
                    Text("\(wallet.trustedMints.count)")
                        .font(.clarity(.medium, textStyle: .body))
                        .foregroundColor(.secondaryTxt)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondaryTxt)
                }
                .padding(.vertical, 8)
                .contentShape(Rectangle())
                .onTapGesture {
                    showWalletManagement = true
                }
                
            } else {
                // No wallet - show onboarding
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "wallet.pass")
                            .font(.title2)
                            .foregroundColor(.accent)
                        
                        VStack(alignment: .leading) {
                            Text("Cashu Wallet")
                                .font(.clarity(.semibold, textStyle: .body))
                                .foregroundColor(.primaryTxt)
                            
                            Text("Send and receive ecash via Nostr")
                                .font(.clarity(.regular, textStyle: .caption))
                                .foregroundColor(.secondaryTxt)
                        }
                        
                        Spacer()
                    }
                    
                    SecondaryActionButton("Set Up Wallet") {
                        showWalletOnboarding = true
                    }
                    .padding(.top, 4)
                }
                .padding(.vertical, 8)
            }
        } header: {
            Text("Wallet")
                .foregroundColor(.primaryTxt)
                .font(.clarity(.semibold, textStyle: .headline))
                .textCase(nil)
                .listRowInsets(EdgeInsets())
                .padding(.vertical, 15)
        }
        .listRowGradientBackground()
        .task {
            await loadWallet()
        }
        .sheet(isPresented: $showWalletManagement) {
            if let wallet = wallet {
                NavigationStack {
                    WalletManagementView(wallet: wallet)
                }
            }
        }
        .sheet(isPresented: $showWalletOnboarding) {
            NavigationStack {
                WalletOnboardingView { newWallet in
                    self.wallet = newWallet
                    Task {
                        await loadBalance()
                    }
                }
            }
        }
    }
    
    private func loadWallet() async {
        guard let author = currentUser.author else { return }
        
        do {
            let wallets = try await walletService.loadWallets(for: author)
            if let firstWallet = wallets.first {
                self.wallet = firstWallet
                await loadBalance()
            }
        } catch {
            print("Failed to load wallet: \(error)")
        }
    }
    
    private func loadBalance() async {
        guard let wallet = wallet,
              let author = currentUser.author else { return }
        
        isLoadingBalance = true
        do {
            let newBalance = try await walletService.getBalance(for: wallet, author: author)
            await MainActor.run {
                self.balance = newBalance
                self.isLoadingBalance = false
            }
        } catch {
            print("Failed to load balance: \(error)")
            await MainActor.run {
                self.isLoadingBalance = false
            }
        }
    }
}