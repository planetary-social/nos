import SwiftUI

/// A button that opens the wallet view when tapped.
struct WalletButton: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingWalletView = false
    
    var body: some View {
        Button {
            showingWalletView = true
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(
                        colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(width: 44, height: 44)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
                
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .sheet(isPresented: $showingWalletView) {
            WalletView()
                .preferredColorScheme(colorScheme)
        }
    }
}

#Preview {
    WalletButton()
        .padding()
        .previewLayout(.sizeThatFits)
}