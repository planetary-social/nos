// ABOUTME: Onboarding flow for creating or restoring a Cashu wallet
// ABOUTME: Guides users through wallet creation, mint selection, and nutzap setup

import SwiftUI
import Dependencies

struct WalletOnboardingView: View {
    let onComplete: (CashuWallet) -> Void
    
    @Dependency(\.persistenceController) private var persistenceController
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(CurrentUser.self) private var currentUser
    
    @State private var currentStep: OnboardingStep = .welcome
    @State private var walletName = ""
    @State private var selectedMint = "https://mint.minibits.cash/Bitcoin"
    @State private var customMintURL = ""
    @State private var enableNutzaps = true
    @State private var selectedRelays: Set<String> = ["wss://relay.damus.io", "wss://nos.social"]
    @State private var isCreatingWallet = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private var walletService: CashuWalletService {
        CashuWalletService(context: viewContext)
    }
    
    enum OnboardingStep: Int, CaseIterable {
        case welcome = 0
        case nameWallet = 1
        case selectMint = 2
        case nutzapSetup = 3
        case complete = 4
    }
    
    private let popularMints = [
        ("Minibits", "https://mint.minibits.cash/Bitcoin"),
        ("LNbits Legend", "https://legend.lnbits.com/cashu/api/v1/4gr9Xcmz3XEkUNwiBiQGoC"),
        ("8333.space", "https://8333.space:3338"),
        ("Custom", "custom")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            ProgressView(value: Double(currentStep.rawValue), total: Double(OnboardingStep.allCases.count - 1))
                .tint(.accent)
                .padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 24) {
                    switch currentStep {
                    case .welcome:
                        welcomeStep
                    case .nameWallet:
                        nameWalletStep
                    case .selectMint:
                        selectMintStep
                    case .nutzapSetup:
                        nutzapSetupStep
                    case .complete:
                        completeStep
                    }
                }
                .padding()
            }
            
            // Navigation buttons
            navigationButtons
        }
        .background(Color.appBg)
        .nosNavigationBar("Create Wallet")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .font(.clarity(.medium, textStyle: .body))
                .foregroundColor(.primaryTxt)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "wallet.pass.fill")
                .font(.system(size: 80))
                .foregroundColor(.accent)
                .padding(.top, 40)
            
            Text("Welcome to Cashu")
                .font(.clarity(.bold, textStyle: .largeTitle))
                .foregroundColor(.primaryTxt)
            
            Text("Send and receive Bitcoin instantly through Nostr with ecash")
                .font(.clarity(.regular, textStyle: .body))
                .foregroundColor(.secondaryTxt)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(
                    icon: "bolt.fill",
                    title: "Lightning Fast",
                    description: "Instant payments with no fees between Cashu users"
                )
                
                FeatureRow(
                    icon: "lock.fill",
                    title: "Private",
                    description: "Enhanced privacy with unlinkable ecash tokens"
                )
                
                FeatureRow(
                    icon: "arrow.left.arrow.right",
                    title: "Interoperable",
                    description: "Works with any app supporting NIP-60 & NIP-61"
                )
            }
            .padding(.top, 20)
        }
    }
    
    private var nameWalletStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Name Your Wallet")
                .font(.clarity(.semibold, textStyle: .title2))
                .foregroundColor(.primaryTxt)
            
            Text("Choose a name to identify this wallet")
                .font(.clarity(.regular, textStyle: .body))
                .foregroundColor(.secondaryTxt)
            
            TextField("My Cashu Wallet", text: $walletName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.clarity(.regular, textStyle: .body))
            
            Text("This name is only visible to you")
                .font(.clarity(.regular, textStyle: .caption))
                .foregroundColor(.secondaryTxt)
            
            Spacer()
        }
        .padding(.top, 40)
    }
    
    private var selectMintStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Select a Mint")
                .font(.clarity(.semibold, textStyle: .title2))
                .foregroundColor(.primaryTxt)
            
            Text("Mints are servers that issue and redeem ecash tokens")
                .font(.clarity(.regular, textStyle: .body))
                .foregroundColor(.secondaryTxt)
            
            VStack(spacing: 12) {
                ForEach(popularMints, id: \.1) { name, url in
                    MintSelectionRow(
                        name: name,
                        url: url == "custom" ? customMintURL : url,
                        isSelected: selectedMint == url,
                        isCustom: url == "custom"
                    ) {
                        selectedMint = url
                    }
                }
            }
            
            if selectedMint == "custom" {
                TextField("https://mint.example.com", text: $customMintURL)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.clarity(.regular, textStyle: .body))
                    .autocapitalization(.none)
                    .keyboardType(.URL)
                    .padding(.top, 8)
            }
            
            Text("⚠️ Only use mints you trust. Mint operators can see your balance.")
                .font(.clarity(.regular, textStyle: .caption))
                .foregroundColor(.orange)
                .padding(.top, 8)
            
            Spacer()
        }
    }
    
    private var nutzapSetupStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Enable Nutzaps")
                .font(.clarity(.semibold, textStyle: .title2))
                .foregroundColor(.primaryTxt)
            
            Text("Allow others to send you ecash through Nostr")
                .font(.clarity(.regular, textStyle: .body))
                .foregroundColor(.secondaryTxt)
            
            NosToggle("Enable nutzap receiving", isOn: $enableNutzaps)
                .padding(.vertical, 8)
            
            if enableNutzaps {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select relays to receive nutzaps on:")
                        .font(.clarity(.medium, textStyle: .body))
                        .foregroundColor(.primaryTxt)
                    
                    ForEach(["wss://relay.damus.io", "wss://nos.social", "wss://relay.nostr.band"], id: \.self) { relay in
                        HStack {
                            Image(systemName: selectedRelays.contains(relay) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedRelays.contains(relay) ? .accent : .secondaryTxt)
                            
                            Text(relay)
                                .font(.clarity(.regular, textStyle: .body))
                                .foregroundColor(.primaryTxt)
                            
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedRelays.contains(relay) {
                                selectedRelays.remove(relay)
                            } else {
                                selectedRelays.insert(relay)
                            }
                        }
                    }
                }
                .padding(.top, 8)
            }
            
            Spacer()
        }
    }
    
    private var completeStep: some View {
        VStack(spacing: 20) {
            if isCreatingWallet {
                ProgressView()
                    .tint(.accent)
                    .scaleEffect(1.5)
                    .padding(.top, 60)
                
                Text("Creating your wallet...")
                    .font(.clarity(.medium, textStyle: .body))
                    .foregroundColor(.secondaryTxt)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                    .padding(.top, 40)
                
                Text("Wallet Created!")
                    .font(.clarity(.bold, textStyle: .largeTitle))
                    .foregroundColor(.primaryTxt)
                
                Text("You're ready to send and receive ecash")
                    .font(.clarity(.regular, textStyle: .body))
                    .foregroundColor(.secondaryTxt)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 12) {
                    InfoRow(label: "Wallet Name", value: walletName.isEmpty ? "My Cashu Wallet" : walletName)
                    InfoRow(label: "Primary Mint", value: URL(string: getMintURL())?.host ?? getMintURL())
                    InfoRow(label: "Nutzaps", value: enableNutzaps ? "Enabled" : "Disabled")
                }
                .padding(.top, 30)
            }
            
            Spacer()
        }
    }
    
    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if currentStep != .welcome && currentStep != .complete {
                SecondaryActionButton("Back") {
                    withAnimation {
                        currentStep = OnboardingStep(rawValue: currentStep.rawValue - 1) ?? .welcome
                    }
                }
            }
            
            if currentStep == .complete && !isCreatingWallet {
                ActionButton("Done") {
                    dismiss()
                }
            } else if currentStep != .complete {
                ActionButton(nextButtonTitle) {
                    if currentStep == .nutzapSetup {
                        Task {
                            await createWallet()
                        }
                    } else {
                        withAnimation {
                            currentStep = OnboardingStep(rawValue: currentStep.rawValue + 1) ?? .complete
                        }
                    }
                }
                .disabled(!canProceed)
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    private var nextButtonTitle: String {
        switch currentStep {
        case .welcome:
            return "Get Started"
        case .nameWallet, .selectMint:
            return "Continue"
        case .nutzapSetup:
            return "Create Wallet"
        case .complete:
            return "Done"
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case .welcome, .nutzapSetup, .complete:
            return true
        case .nameWallet:
            return true // Name is optional
        case .selectMint:
            return selectedMint != "custom" || !customMintURL.isEmpty
        }
    }
    
    private func getMintURL() -> String {
        if selectedMint == "custom" {
            return customMintURL
        }
        return selectedMint
    }
    
    private func createWallet() async {
        guard let author = currentUser.author else { return }
        
        withAnimation {
            currentStep = .complete
            isCreatingWallet = true
        }
        
        do {
            let finalName = walletName.isEmpty ? "My Cashu Wallet" : walletName
            let finalMint = getMintURL()
            
            // Create wallet
            let wallet = try await walletService.createWallet(
                name: finalName,
                mintURL: finalMint,
                for: author
            )
            
            // Publish nutzap info if enabled
            if enableNutzaps {
                let nutzapInfo = try wallet.createNutzapInfoEvent(
                    author: author,
                    relays: Array(selectedRelays),
                    p2pkPubkey: wallet.walletPublicKey
                )
                nutzapInfo.createdAt = Date()
                try viewContext.save()
            }
            
            await MainActor.run {
                isCreatingWallet = false
                onComplete(wallet)
            }
        } catch {
            await MainActor.run {
                isCreatingWallet = false
                errorMessage = error.localizedDescription
                showError = true
                currentStep = .nutzapSetup
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accent)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.clarity(.semibold, textStyle: .body))
                    .foregroundColor(.primaryTxt)
                
                Text(description)
                    .font(.clarity(.regular, textStyle: .caption))
                    .foregroundColor(.secondaryTxt)
            }
            
            Spacer()
        }
    }
}

struct MintSelectionRow: View {
    let name: String
    let url: String
    let isSelected: Bool
    let isCustom: Bool
    let action: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .accent : .secondaryTxt)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.clarity(.medium, textStyle: .body))
                    .foregroundColor(.primaryTxt)
                
                if !isCustom {
                    Text(URL(string: url)?.host ?? url)
                        .font(.clarity(.regular, textStyle: .caption))
                        .foregroundColor(.secondaryTxt)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isSelected ? Color.accent.opacity(0.1) : Color.backgroundSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.clarity(.regular, textStyle: .body))
                .foregroundColor(.secondaryTxt)
            
            Spacer()
            
            Text(value)
                .font(.clarity(.medium, textStyle: .body))
                .foregroundColor(.primaryTxt)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color.backgroundSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}