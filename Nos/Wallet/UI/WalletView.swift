import SwiftUI
import Logger
import Dependencies

struct WalletView: View {
    @Dependency(\.walletManager) private var walletManager
    @State private var selectedTab: WalletTab = .balance
    @State private var showingCreateWallet = false
    @State private var showingRestoreWallet = false
    @State private var showingSendView = false
    @State private var showingReceiveView = false
    @State private var showingMintView = false
    @State private var showingMeltView = false
    @State private var showingAddMintView = false
    @State private var restorationMnemonic = ""
    @State private var showingTestResults = false
    
    enum WalletTab {
        case balance
        case transactions
        case settings
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if walletManager.isWalletInitialized {
                    walletContent
                } else {
                    noWalletView
                }
            }
            .navigationTitle("Cashu Wallet")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingCreateWallet) {
                createWalletView
            }
            .sheet(isPresented: $showingRestoreWallet) {
                restoreWalletView
            }
            .sheet(isPresented: $showingSendView) {
                Text("Send View")
                    .padding()
            }
            .sheet(isPresented: $showingReceiveView) {
                Text("Receive View")
                    .padding()
            }
            .sheet(isPresented: $showingMintView) {
                Text("Mint View")
                    .padding()
            }
            .sheet(isPresented: $showingMeltView) {
                Text("Pay View")
                    .padding()
            }
            .sheet(isPresented: $showingAddMintView) {
                Text("Add Mint View")
                    .padding()
            }
            .sheet(isPresented: $showingTestResults) {
                TestCashuSwift.displayResults()
                    .navigationTitle("CashuSwift Test Results")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Close") {
                                showingTestResults = false
                            }
                        }
                    }
            }
        }
    }
    
    // MARK: - Wallet Content Views
    
    var walletContent: some View {
        VStack {
            balanceCard
            
            tabSelector
            
            tabContent
            
            actionButtons
        }
        .padding()
    }
    
    var balanceCard: some View {
        VStack(spacing: 8) {
            Text("Balance")
                .font(.clarity(.regular, textStyle: .subheadline))
                .foregroundColor(.secondaryTxt)
            
            Text("\(walletManager.balance) sats")
                .font(.clarity(.bold, textStyle: .title))
                .foregroundColor(.primaryTxt)
            
            HStack {
                Text("≈ $\(Double(walletManager.balance) / 100000, specifier: "%.2f")")
                    .font(.clarity(.regular, textStyle: .caption))
                    .foregroundColor(.secondaryTxt)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient.cardBackground
                .cornerRadius(20)
        )
    }
    
    var tabSelector: some View {
        HStack {
            ForEach([WalletTab.balance, WalletTab.transactions, WalletTab.settings], id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack {
                        Image(systemName: iconForTab(tab))
                            .font(.system(size: 22))
                        
                        Text(titleForTab(tab))
                            .font(.clarity(.medium, textStyle: .caption))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundColor(selectedTab == tab ? .accentColor : .secondaryTxt)
                    .background(
                        selectedTab == tab ?
                        Color.secondaryBg.opacity(0.3).cornerRadius(10) : nil
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical)
    }
    
    var tabContent: some View {
        Group {
            switch selectedTab {
            case .balance:
                balanceTabView
            case .transactions:
                transactionsTabView
            case .settings:
                settingsTabView
            }
        }
    }
    
    var balanceTabView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mints")
                .font(.clarity(.semibold, textStyle: .headline))
                .foregroundColor(.primaryTxt)
            
            if walletManager.mints.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "server.rack")
                        .font(.system(size: 40))
                        .foregroundColor(.secondaryTxt)
                    
                    Text("No mints added yet")
                        .font(.clarity(.medium, textStyle: .body))
                        .foregroundColor(.secondaryTxt)
                    
                    Button {
                        showingAddMintView = true
                    } label: {
                        Text("Add Mint")
                            .font(.clarity(.bold, textStyle: .callout))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                ForEach(walletManager.mints) { mint in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(mint.name)
                                .font(.clarity(.medium, textStyle: .body))
                                .foregroundColor(.primaryTxt)
                            
                            Text(mint.url.host ?? mint.url.absoluteString)
                                .font(.clarity(.regular, textStyle: .caption))
                                .foregroundColor(.secondaryTxt)
                        }
                        
                        Spacer()
                        
                        Text("\(mint.balance) sats")
                            .font(.clarity(.semibold, textStyle: .body))
                            .foregroundColor(.primaryTxt)
                    }
                    .padding()
                    .background(
                        LinearGradient.cardBackground
                            .cornerRadius(12)
                    )
                }
                
                Button {
                    showingAddMintView = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Mint")
                    }
                    .font(.clarity(.medium, textStyle: .callout))
                    .padding(.top, 8)
                    .foregroundColor(.accentColor)
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
    
    var transactionsTabView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Transactions")
                .font(.clarity(.semibold, textStyle: .headline))
                .foregroundColor(.primaryTxt)
            
            if walletManager.transactions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 40))
                        .foregroundColor(.secondaryTxt)
                    
                    Text("No transactions yet")
                        .font(.clarity(.medium, textStyle: .body))
                        .foregroundColor(.secondaryTxt)
                    
                    Text("Send, receive, or mint tokens to get started")
                        .font(.clarity(.regular, textStyle: .caption))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondaryTxt)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                ForEach(walletManager.transactions) { transaction in
                    HStack(spacing: 16) {
                        Image(systemName: transaction.type.iconName)
                            .font(.system(size: 24))
                            .foregroundColor(Color(transaction.status.color))
                            .frame(width: 40, height: 40)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(transaction.type.displayName)
                                .font(.clarity(.medium, textStyle: .body))
                                .foregroundColor(.primaryTxt)
                            
                            Text(transaction.timestamp, style: .date)
                                .font(.clarity(.regular, textStyle: .caption))
                                .foregroundColor(.secondaryTxt)
                            
                            if let memo = transaction.memo {
                                Text(memo)
                                    .font(.clarity(.regular, textStyle: .caption))
                                    .foregroundColor(.secondaryTxt)
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer()
                        
                        let prefix = transaction.type == .receive || transaction.type == .mint ? "+" : "-"
                        Text("\(prefix)\(transaction.amount) sats")
                            .font(.clarity(.semibold, textStyle: .body))
                            .foregroundColor(transaction.type == .receive || transaction.type == .mint ? .green : .primaryTxt)
                    }
                    .padding()
                    .background(
                        LinearGradient.cardBackground
                            .cornerRadius(12)
                    )
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
    
    var settingsTabView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.clarity(.semibold, textStyle: .headline))
                .foregroundColor(.primaryTxt)
            
            settingsSection(title: "Wallet", items: [
                SettingItem(title: "Backup Wallet", icon: "lock.doc.fill", action: {}),
                SettingItem(title: "View Seed Phrase", icon: "key.fill", action: {})
            ])
            
            settingsSection(title: "Preferences", items: [
                SettingItem(title: "Currency Display", icon: "dollarsign.circle.fill", action: {}),
                SettingItem(title: "Default Mint", icon: "server.rack", action: {})
            ])
            
            settingsSection(title: "About", items: [
                SettingItem(title: "What is Cashu?", icon: "info.circle.fill", action: {}),
                SettingItem(title: "Privacy Policy", icon: "eye.slash.fill", action: {})
            ])
            
            // Test section for Macadamia integration
            #if DEBUG
            settingsSection(title: "Developer", items: [
                SettingItem(title: "Test CashuSwift Integration", icon: "gear", action: {
                    Task {
                        await TestCashuSwift.runTests()
                        showingTestResults = true
                    }
                })
            ])
            #endif
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
    
    func settingsSection(title: String, items: [SettingItem]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.clarity(.medium, textStyle: .body))
                .foregroundColor(.primaryTxt)
                .padding(.bottom, 4)
            
            ForEach(items) { item in
                Button {
                    item.action()
                } label: {
                    HStack {
                        Image(systemName: item.icon)
                            .frame(width: 24, height: 24)
                            .foregroundColor(.accentColor)
                        
                        Text(item.title)
                            .font(.clarity(.regular, textStyle: .body))
                            .foregroundColor(.primaryTxt)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.secondaryTxt)
                    }
                    .padding(.vertical, 12)
                }
                .buttonStyle(PlainButtonStyle())
                
                if item.id != items.last?.id {
                    Divider()
                        .padding(.leading, 36)
                }
            }
        }
        .padding()
        .background(
            LinearGradient.cardBackground
                .cornerRadius(12)
        )
    }
    
    struct SettingItem: Identifiable {
        let id = UUID()
        let title: String
        let icon: String
        let action: () -> Void
    }
    
    // MARK: - Action Buttons
    
    var actionButtons: some View {
        HStack(spacing: 16) {
            actionButton(
                title: "Send",
                icon: "arrow.up",
                color: .accentColor
            ) {
                showingSendView = true
            }
            
            actionButton(
                title: "Receive",
                icon: "arrow.down",
                color: .accentColor
            ) {
                showingReceiveView = true
            }
            
            actionButton(
                title: "Mint",
                icon: "plus",
                color: .accentColor
            ) {
                showingMintView = true
            }
            
            actionButton(
                title: "Pay",
                icon: "bolt",
                color: .accentColor
            ) {
                showingMeltView = true
            }
        }
        .padding(.vertical)
    }
    
    func actionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(color)
                    .clipShape(Circle())
                
                Text(title)
                    .font(.clarity(.medium, textStyle: .caption))
                    .foregroundColor(.primaryTxt)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Wallet Creation/Restoration
    
    var noWalletView: some View {
        VStack(spacing: 24) {
            Image(systemName: "wallet.pass.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
                .padding(.bottom, 16)
            
            Text("No Cashu Wallet")
                .font(.clarity(.bold, textStyle: .title2))
                .foregroundColor(.primaryTxt)
            
            Text("Create or restore a Cashu wallet to start using Ecash in Nos")
                .font(.clarity(.regular, textStyle: .body))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondaryTxt)
                .padding(.horizontal)
            
            VStack(spacing: 16) {
                Button {
                    showingCreateWallet = true
                } label: {
                    Text("Create New Wallet")
                        .font(.clarity(.bold, textStyle: .body))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
                
                Button {
                    showingRestoreWallet = true
                } label: {
                    Text("Restore Existing Wallet")
                        .font(.clarity(.bold, textStyle: .body))
                        .foregroundColor(.accentColor)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.accentColor, lineWidth: 2)
                        )
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)
        }
        .padding()
    }
    
    var createWalletView: some View {
        VStack(spacing: 24) {
            Text("Create New Wallet")
                .font(.clarity(.bold, textStyle: .title2))
                .padding(.top)
            
            Text("A new Cashu wallet will be created for you with a randomly generated seed phrase. Make sure to backup this phrase in a secure location!")
                .font(.clarity(.regular, textStyle: .body))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                Task {
                    do {
                        try await walletManager.createWallet()
                        showingCreateWallet = false
                    } catch {
                        Log.error("Failed to create wallet: \(error.localizedDescription)")
                    }
                }
            } label: {
                Text("Create Wallet")
                    .font(.clarity(.bold, textStyle: .body))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Button {
                showingCreateWallet = false
            } label: {
                Text("Cancel")
                    .font(.clarity(.medium, textStyle: .body))
                    .foregroundColor(.secondaryTxt)
            }
            .padding(.bottom)
        }
        .padding()
        .frame(maxWidth: 400)
        .background(Color.appBg)
        .cornerRadius(20)
    }
    
    var restoreWalletView: some View {
        VStack(spacing: 24) {
            Text("Restore Wallet")
                .font(.clarity(.bold, textStyle: .title2))
                .padding(.top)
            
            Text("Enter your 12-word seed phrase to restore your wallet")
                .font(.clarity(.regular, textStyle: .body))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            TextEditor(text: $restorationMnemonic)
                .font(.clarity(.regular, textStyle: .body))
                .padding()
                .frame(height: 120)
                .background(Color.secondaryBg.opacity(0.3))
                .cornerRadius(12)
                .padding(.horizontal)
            
            Button {
                Task {
                    do {
                        try await walletManager.restoreWallet(mnemonic: restorationMnemonic)
                        showingRestoreWallet = false
                    } catch {
                        Log.error("Failed to restore wallet: \(error.localizedDescription)")
                    }
                }
            } label: {
                Text("Restore Wallet")
                    .font(.clarity(.bold, textStyle: .body))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .disabled(restorationMnemonic.split(separator: " ").count != 12)
            
            Button {
                showingRestoreWallet = false
            } label: {
                Text("Cancel")
                    .font(.clarity(.medium, textStyle: .body))
                    .foregroundColor(.secondaryTxt)
            }
            .padding(.bottom)
        }
        .padding()
        .frame(maxWidth: 400)
        .background(Color.appBg)
        .cornerRadius(20)
    }
    
    // MARK: - Helper Methods
    
    func iconForTab(_ tab: WalletTab) -> String {
        switch tab {
        case .balance:
            return "wallet.pass.fill"
        case .transactions:
            return "arrow.left.arrow.right"
        case .settings:
            return "gear"
        }
    }
    
    func titleForTab(_ tab: WalletTab) -> String {
        switch tab {
        case .balance:
            return "Balance"
        case .transactions:
            return "History"
        case .settings:
            return "Settings"
        }
    }
}

#Preview {
    WalletView()
        .preferredColorScheme(.dark)
}