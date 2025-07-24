// ABOUTME: Sheet interface for sending nutzaps with amount selection and comment
// ABOUTME: Handles wallet selection, balance checking, and nutzap transaction flow

import SwiftUI
import Dependencies

struct NutzapSendingSheet: View {
    let recipient: Author
    let note: Event?
    let onComplete: (Int) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(CurrentUser.self) private var currentUser
    @ObservationIgnored @Dependency(\.analytics) private var analytics
    
    @State private var selectedAmount = 21
    @State private var customAmount = ""
    @State private var comment = ""
    @State private var wallet: CashuWallet?
    @State private var balance = 0
    @State private var isSending = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let presetAmounts = [21, 69, 100, 420, 1000, 5000]
    
    private var walletService: CashuWalletService {
        CashuWalletService(context: viewContext)
    }
    
    private var nutzapService: NutzapService {
        NutzapService(context: viewContext, walletService: walletService)
    }
    
    private var finalAmount: Int {
        if !customAmount.isEmpty {
            return Int(customAmount) ?? 0
        }
        return selectedAmount
    }
    
    private var canSend: Bool {
        finalAmount > 0 && finalAmount <= balance && !isSending
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Recipient info
                    recipientSection
                    
                    // Amount selection
                    amountSection
                    
                    // Comment
                    commentSection
                    
                    // Wallet info
                    walletSection
                }
                .padding()
            }
            .background(Color.appBg)
            .nosNavigationBar("Send Nutzap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.clarity(.medium, textStyle: .body))
                    .foregroundColor(.primaryTxt)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isSending {
                        ProgressView()
                            .tint(.accent)
                    } else {
                        Button("Send") {
                            Task {
                                await sendNutzap()
                            }
                        }
                        .font(.clarity(.semibold, textStyle: .body))
                        .foregroundColor(.accent)
                        .disabled(!canSend)
                    }
                }
            }
            .task {
                await loadWallet()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private var recipientSection: some View {
        VStack(spacing: 12) {
            AvatarView(imageUrl: recipient.profilePhotoURL, size: 60)
            
            Text(recipient.bestDisplayName)
                .font(.clarity(.semibold, textStyle: .title3))
                .foregroundColor(.primaryTxt)
            
            if let nip05 = recipient.nip05 {
                Text(nip05)
                    .font(.clarity(.regular, textStyle: .caption))
                    .foregroundColor(.secondaryTxt)
            }
        }
    }
    
    private var amountSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Amount")
                .font(.clarity(.semibold, textStyle: .headline))
                .foregroundColor(.primaryTxt)
            
            // Preset amounts
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                ForEach(presetAmounts, id: \.self) { amount in
                    Button {
                        selectedAmount = amount
                        customAmount = ""
                    } label: {
                        VStack(spacing: 2) {
                            Text("\(amount)")
                                .font(.clarity(.semibold, textStyle: .body))
                            Text("sats")
                                .font(.clarity(.regular, textStyle: .caption))
                        }
                        .foregroundColor(selectedAmount == amount && customAmount.isEmpty ? .white : .primaryTxt)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            selectedAmount == amount && customAmount.isEmpty
                                ? Color.accent
                                : Color.backgroundSurface
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            
            // Custom amount
            HStack {
                TextField("Custom amount", text: $customAmount)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: customAmount) { _, _ in
                        // Clear preset selection when typing custom
                        selectedAmount = 0
                    }
                
                Text("sats")
                    .font(.clarity(.regular, textStyle: .body))
                    .foregroundColor(.secondaryTxt)
            }
        }
    }
    
    private var commentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Comment (optional)")
                .font(.clarity(.semibold, textStyle: .headline))
                .foregroundColor(.primaryTxt)
            
            TextField("Add a message...", text: $comment, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...6)
        }
    }
    
    private var walletSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("From Wallet")
                    .font(.clarity(.semibold, textStyle: .headline))
                    .foregroundColor(.primaryTxt)
                
                Spacer()
                
                if let wallet = wallet {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(balance) sats")
                            .font(.clarity(.semibold, textStyle: .body))
                            .foregroundColor(finalAmount > balance ? .red : .primaryTxt)
                        Text("available")
                            .font(.clarity(.regular, textStyle: .caption))
                            .foregroundColor(.secondaryTxt)
                    }
                }
            }
            
            if let wallet = wallet {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(wallet.name)
                            .font(.clarity(.medium, textStyle: .body))
                            .foregroundColor(.primaryTxt)
                        
                        Text(URL(string: wallet.mintURL)?.host ?? wallet.mintURL)
                            .font(.clarity(.regular, textStyle: .caption))
                            .foregroundColor(.secondaryTxt)
                    }
                    
                    Spacer()
                    
                    if finalAmount > balance {
                        Text("Insufficient balance")
                            .font(.clarity(.regular, textStyle: .caption))
                            .foregroundColor(.red)
                    }
                }
                .padding()
                .background(Color.backgroundSurface)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Text("Loading wallet...")
                    .font(.clarity(.regular, textStyle: .body))
                    .foregroundColor(.secondaryTxt)
            }
        }
    }
    
    private func loadWallet() async {
        guard let currentAuthor = currentUser.author else { return }
        
        do {
            // Load wallet
            let wallets = try await walletService.loadWallets(for: currentAuthor)
            if let firstWallet = wallets.first {
                self.wallet = firstWallet
                
                // Load balance
                let walletBalance = try await walletService.getBalance(
                    for: firstWallet,
                    author: currentAuthor
                )
                
                await MainActor.run {
                    self.balance = walletBalance
                }
            } else {
                await MainActor.run {
                    errorMessage = "No wallet found. Please set up a wallet first."
                    showError = true
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load wallet: \(error.localizedDescription)"
                showError = true
            }
        }
    }
    
    private func sendNutzap() async {
        guard let wallet = wallet,
              let currentAuthor = currentUser.author,
              let recipientPubkey = recipient.hexadecimalPublicKey else { return }
        
        isSending = true
        
        do {
            let nutzap = try await nutzapService.sendNutzap(
                amount: finalAmount,
                to: recipientPubkey,
                from: wallet,
                comment: comment.isEmpty ? nil : comment,
                author: currentAuthor,
                referencedEvent: note
            )
            
            await MainActor.run {
                onComplete(finalAmount)
                dismiss()
            }
        } catch {
            await MainActor.run {
                isSending = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}