import SwiftUI

/// Tab bar item for accessing the wallet functionality in Nos.
struct WalletTab: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingWalletView = false
    
    var body: some View {
        Button {
            showingWalletView = true
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 22))
                
                Text("Wallet")
                    .font(.clarity(.medium, textStyle: .caption))
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(.secondaryTxt)
        }
        .sheet(isPresented: $showingWalletView) {
            WalletView()
                .preferredColorScheme(colorScheme)
        }
    }
}

#Preview {
    HStack {
        WalletTab()
        WalletTab()
    }
    .padding()
    .previewLayout(.sizeThatFits)
}