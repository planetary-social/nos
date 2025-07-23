// ABOUTME: View for backing up wallet private key and configuration
// ABOUTME: Allows users to export their wallet data for recovery

import SwiftUI

struct WalletBackupView: View {
    let wallet: CashuWallet
    
    @Environment(\.dismiss) private var dismiss
    @State private var showPrivateKey = false
    @State private var copyButtonState: CopyButtonState = .copy
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Warning
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        
                        Text("Important: Keep Your Backup Safe")
                            .font(.clarity(.semibold, textStyle: .title3))
                            .foregroundColor(.primaryTxt)
                        
                        Text("Anyone with access to your wallet private key can spend your funds. Never share it publicly.")
                            .font(.clarity(.regular, textStyle: .body))
                            .foregroundColor(.secondaryTxt)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Wallet Info
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Wallet Information")
                            .font(.clarity(.semibold, textStyle: .headline))
                            .foregroundColor(.primaryTxt)
                        
                        InfoRow(label: "Name", value: wallet.name)
                        InfoRow(label: "Primary Mint", value: URL(string: wallet.mintURL)?.host ?? wallet.mintURL)
                        InfoRow(label: "Trusted Mints", value: "\(wallet.trustedMints.count)")
                    }
                    
                    // Private Key Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Wallet Private Key")
                            .font(.clarity(.semibold, textStyle: .headline))
                            .foregroundColor(.primaryTxt)
                        
                        VStack(spacing: 12) {
                            if showPrivateKey {
                                Text(wallet.walletPrivateKey)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.primaryTxt)
                                    .padding()
                                    .background(Color.backgroundSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .textSelection(.enabled)
                            } else {
                                Text(String(repeating: "•", count: 64))
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondaryTxt)
                                    .padding()
                                    .background(Color.backgroundSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            
                            HStack(spacing: 12) {
                                SecondaryActionButton(showPrivateKey ? "Hide" : "Reveal") {
                                    showPrivateKey.toggle()
                                }
                                
                                ZStack {
                                    SecondaryActionButton("Copy", image: .copyIcon) {
                                        UIPasteboard.general.string = wallet.walletPrivateKey
                                        copyButtonState = .copied
                                        Task { @MainActor in
                                            try await Task.sleep(for: .seconds(3))
                                            copyButtonState = .copy
                                        }
                                    }
                                    .opacity(copyButtonState == .copy ? 1 : 0)
                                    
                                    SecondaryActionButton("Copied ✓") { }
                                        .disabled(true)
                                        .opacity(copyButtonState == .copied ? 1 : 0)
                                }
                                .fixedSize()
                            }
                        }
                    }
                    
                    // Export Options
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Export Options")
                            .font(.clarity(.semibold, textStyle: .headline))
                            .foregroundColor(.primaryTxt)
                        
                        Text("You can restore your wallet in any app that supports NIP-60")
                            .font(.clarity(.regular, textStyle: .caption))
                            .foregroundColor(.secondaryTxt)
                        
                        SecondaryActionButton("Export as QR Code", image: Image(systemName: "qrcode")) {
                            // TODO: Show QR code with wallet data
                        }
                        
                        SecondaryActionButton("Share Backup File", image: Image(systemName: "square.and.arrow.up")) {
                            // TODO: Create and share backup file
                        }
                    }
                }
                .padding()
            }
            .background(Color.appBg)
            .nosNavigationBar("Backup Wallet")
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
        }
    }
}