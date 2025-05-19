import SwiftUI
import Dependencies
import Logger

/// A button that opens the wallet view when tapped.
struct WalletButton: View {
    @Environment(\.colorScheme) private var colorScheme
    @Dependency(\.walletManager) private var walletManager
    
    @State private var showingWalletView = false
    @State private var showingMacadamiaLauncher = false
    @State private var isLoading = false
    
    // Use of FeatureFlags to control behavior
    @Dependency(\.featureFlags) private var featureFlags
    
    // Determine whether to use embedded or Macadamia wallet
    private var shouldUseMacadamia: Bool {
        return featureFlags.isEnabled(.useMacadamiaWallet)
    }
    
    var body: some View {
        Button {
            if shouldUseMacadamia {
                showingMacadamiaLauncher = true
            } else {
                showingWalletView = true
            }
        } label: {
            ZStack {
                // Transparent background to match parent view
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.clear)
                    .frame(width: 44, height: 44)
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.accentColor)
                }
            }
        }
        .sheet(isPresented: $showingWalletView) {
            WalletView()
                .preferredColorScheme(colorScheme)
        }
        .sheet(isPresented: $showingMacadamiaLauncher) {
            MacadamiaWalletLauncherView(isLoading: $isLoading) {
                walletManager.launchMacadamiaWallet()
                
                // Close the launcher after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    showingMacadamiaLauncher = false
                    isLoading = false
                }
            }
        }
    }
}

/// A view that helps launch the Macadamia wallet
struct MacadamiaWalletLauncherView: View {
    @Binding var isLoading: Bool
    var launchAction: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "creditcard.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
                .padding()
            
            Text("Launch Macadamia Wallet")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("The Macadamia wallet provides a full Bitcoin Ecash experience. Tap the button below to launch it.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                isLoading = true
                launchAction()
            } label: {
                Text("Launch Wallet")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .disabled(isLoading)
            
            if isLoading {
                ProgressView("Launching...")
                    .padding()
            }
            
            Button("Cancel") {
                dismiss()
            }
            .padding(.top, 8)
        }
        .padding()
        .frame(maxWidth: 400)
    }
}

#Preview {
    WalletButton()
        .padding()
        .previewLayout(.sizeThatFits)
        .background(Color.gray.opacity(0.1))
}