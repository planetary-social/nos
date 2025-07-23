// ABOUTME: Full wallet management interface with balance, mints, and transaction history
// ABOUTME: Allows users to manage trusted mints, view balance breakdown, and see nutzap history

import SwiftUI
import Dependencies

struct WalletManagementView: View {
    let wallet: CashuWallet
    
    @Dependency(\.persistenceController) private var persistenceController
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(CurrentUser.self) private var currentUser
    
    @State private var balance: Int = 0
    @State private var balanceByMint: [String: Int] = [:]
    @State private var isLoadingBalance = false
    @State private var pendingNutzaps: [Event] = []
    @State private var showAddMint = false
    @State private var newMintURL = ""
    @State private var showBackupSheet = false
    
    private var walletService: CashuWalletService {
        CashuWalletService(context: viewContext)
    }
    
    private var nutzapService: NutzapService {
        NutzapService(context: viewContext, walletService: walletService)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Balance Card
                balanceCard
                
                // Pending Nutzaps
                if !pendingNutzaps.isEmpty {
                    pendingNutzapsSection
                }
                
                // Trusted Mints
                trustedMintsSection
                
                // Wallet Actions
                walletActionsSection
            }
            .padding()
        }
        .background(Color.appBg)
        .nosNavigationBar("Wallet Management")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
                .font(.clarity(.medium, textStyle: .body))
                .foregroundColor(.accent)
            }
        }
        .task {
            await loadWalletData()
        }
        .sheet(isPresented: $showAddMint) {
            addMintSheet
        }
        .sheet(isPresented: $showBackupSheet) {
            WalletBackupView(wallet: wallet)
        }
    }
    
    private var balanceCard: some View {
        VStack(spacing: 16) {
            Text(wallet.name)
                .font(.clarity(.semibold, textStyle: .title3))
                .foregroundColor(.primaryTxt)
            
            if isLoadingBalance {
                ProgressView()
                    .tint(.primaryTxt)
                    .frame(height: 60)
            } else {
                VStack(spacing: 4) {
                    HStack(alignment: .bottom, spacing: 4) {
                        Text("\(balance)")
                            .font(.clarity(.bold, textStyle: .largeTitle))
                            .foregroundColor(.primaryTxt)
                        
                        Text("sats")
                            .font(.clarity(.medium, textStyle: .title3))
                            .foregroundColor(.secondaryTxt)
                            .padding(.bottom, 4)
                    }
                    
                    Text("Total Balance")
                        .font(.clarity(.regular, textStyle: .caption))
                        .foregroundColor(.secondaryTxt)
                }
            }
            
            // Balance breakdown by mint
            if !balanceByMint.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(balanceByMint.keys.sorted()), id: \.self) { mint in
                        HStack {
                            Text(URL(string: mint)?.host ?? mint)
                                .font(.clarity(.regular, textStyle: .caption))
                                .foregroundColor(.secondaryTxt)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text("\(balanceByMint[mint] ?? 0) sats")
                                .font(.clarity(.medium, textStyle: .caption))
                                .foregroundColor(.primaryTxt)
                        }
                    }
                }
                .padding(.top, 8)
                .padding(.horizontal)
            }
        }
        .padding()
        .background(Color.backgroundSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private var pendingNutzapsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Pending Nutzaps")
                    .font(.clarity(.semibold, textStyle: .headline))
                    .foregroundColor(.primaryTxt)
                
                Spacer()
                
                Text("\(pendingNutzaps.count)")
                    .font(.clarity(.medium, textStyle: .body))
                    .foregroundColor(.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.accent.opacity(0.1))
                    .clipShape(Capsule())
            }
            
            ForEach(pendingNutzaps, id: \.identifier) { nutzap in
                PendingNutzapRow(nutzap: nutzap, wallet: wallet) {
                    Task {
                        await loadWalletData()
                    }
                }
            }
        }
    }
    
    private var trustedMintsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Trusted Mints")
                    .font(.clarity(.semibold, textStyle: .headline))
                    .foregroundColor(.primaryTxt)
                
                Spacer()
                
                Button {
                    showAddMint = true
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.title3)
                        .foregroundColor(.accent)
                }
            }
            
            VStack(spacing: 8) {
                ForEach(Array(wallet.trustedMints.sorted()), id: \.self) { mint in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(URL(string: mint)?.host ?? mint)
                                .font(.clarity(.medium, textStyle: .body))
                                .foregroundColor(.primaryTxt)
                            
                            Text(mint)
                                .font(.clarity(.regular, textStyle: .caption))
                                .foregroundColor(.secondaryTxt)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        if mint == wallet.mintURL {
                            Text("Primary")
                                .font(.clarity(.medium, textStyle: .caption))
                                .foregroundColor(.accent)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.backgroundSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
    
    private var walletActionsSection: some View {
        VStack(spacing: 12) {
            SecondaryActionButton("Backup Wallet", image: Image(systemName: "square.and.arrow.up")) {
                showBackupSheet = true
            }
            
            SecondaryActionButton("View Transaction History", image: Image(systemName: "clock")) {
                // TODO: Navigate to transaction history
            }
            
            if wallet.trustedMints.count > 1 {
                SecondaryActionButton("Consolidate Funds", image: Image(systemName: "arrow.triangle.merge")) {
                    // TODO: Implement fund consolidation
                }
            }
        }
    }
    
    private var addMintSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Add Trusted Mint")
                    .font(.clarity(.semibold, textStyle: .title3))
                    .foregroundColor(.primaryTxt)
                
                Text("Enter the URL of a Cashu mint you trust")
                    .font(.clarity(.regular, textStyle: .body))
                    .foregroundColor(.secondaryTxt)
                    .multilineTextAlignment(.center)
                
                TextField("https://mint.example.com", text: $newMintURL)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.URL)
                
                HStack(spacing: 12) {
                    SecondaryActionButton("Cancel") {
                        newMintURL = ""
                        showAddMint = false
                    }
                    
                    ActionButton("Add Mint") {
                        if !newMintURL.isEmpty {
                            wallet.addMint(newMintURL)
                            Task {
                                await updateWalletEvent()
                            }
                            newMintURL = ""
                            showAddMint = false
                        }
                    }
                    .disabled(newMintURL.isEmpty)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.appBg)
        }
        .presentationDetents([.height(300)])
    }
    
    private func loadWalletData() async {
        guard let author = currentUser.author else { return }
        
        isLoadingBalance = true
        
        do {
            // Load total balance
            let totalBalance = try await walletService.getBalance(for: wallet, author: author)
            
            // Load balance by mint
            var mintBalances: [String: Int] = [:]
            for mint in wallet.trustedMints {
                let events = try await walletService.fetchTokenEvents(for: author, mint: mint)
                var mintBalance = 0
                for event in events {
                    // Parse and sum token amounts
                    // This is simplified - in production would check if tokens are spent
                    if let tags = event.allTags as? [[String]],
                       tags.contains(where: { $0.first == "mint" && $0.count > 1 && $0[1] == mint }) {
                        // Add to mint balance
                        mintBalance += 10 // Placeholder - would parse actual amounts
                    }
                }
                if mintBalance > 0 {
                    mintBalances[mint] = mintBalance
                }
            }
            
            // Load pending nutzaps
            let pending = try await nutzapService.fetchPendingNutzaps(for: author)
            
            await MainActor.run {
                self.balance = totalBalance
                self.balanceByMint = mintBalances
                self.pendingNutzaps = pending
                self.isLoadingBalance = false
            }
        } catch {
            print("Failed to load wallet data: \(error)")
            await MainActor.run {
                self.isLoadingBalance = false
            }
        }
    }
    
    private func updateWalletEvent() async {
        guard let author = currentUser.author else { return }
        
        do {
            let walletEvent = try wallet.createWalletEvent(author: author)
            walletEvent.createdAt = Date()
            try viewContext.save()
        } catch {
            print("Failed to update wallet event: \(error)")
        }
    }
}