// ABOUTME: Row component for displaying a pending nutzap that can be redeemed
// ABOUTME: Shows sender, amount, and provides quick redeem action

import SwiftUI
import Dependencies

struct PendingNutzapRow: View {
    let nutzap: Event
    let wallet: CashuWallet
    let onRedeemed: () -> Void
    
    @Dependency(\.persistenceController) private var persistenceController
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(CurrentUser.self) private var currentUser
    
    @State private var isRedeeming = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private var nutzapService: NutzapService {
        NutzapService(
            context: viewContext,
            walletService: CashuWalletService(context: viewContext)
        )
    }
    
    private var amount: String {
        guard let tags = nutzap.allTags as? [[String]] else { return "0" }
        
        for tag in tags {
            if tag.count >= 2 && tag[0] == "amount" {
                return tag[1]
            }
        }
        return "0"
    }
    
    private var comment: String? {
        guard let tags = nutzap.allTags as? [[String]] else { return nil }
        
        for tag in tags {
            if tag.count >= 2 && tag[0] == "comment" {
                return tag[1]
            }
        }
        return nil
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Sender avatar
            if let author = nutzap.author {
                AvatarView(imageUrl: author.profilePhotoURL, size: 40)
            } else {
                Circle()
                    .fill(Color.secondaryTxt.opacity(0.2))
                    .frame(width: 40, height: 40)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(nutzap.author?.bestDisplayName ?? "Unknown")
                        .font(.clarity(.medium, textStyle: .body))
                        .foregroundColor(.primaryTxt)
                        .lineLimit(1)
                    
                    Text("• \(amount) sats")
                        .font(.clarity(.semibold, textStyle: .body))
                        .foregroundColor(.accent)
                }
                
                if let comment = comment {
                    Text(comment)
                        .font(.clarity(.regular, textStyle: .caption))
                        .foregroundColor(.secondaryTxt)
                        .lineLimit(2)
                }
                
                if let createdAt = nutzap.createdAt {
                    Text(createdAt.distanceString())
                        .font(.clarity(.regular, textStyle: .caption))
                        .foregroundColor(.secondaryTxt)
                }
            }
            
            Spacer()
            
            if isRedeeming {
                ProgressView()
                    .tint(.accent)
            } else {
                Button {
                    Task {
                        await redeemNutzap()
                    }
                } label: {
                    Text("Redeem")
                        .font(.clarity(.medium, textStyle: .caption))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accent)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.backgroundSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func redeemNutzap() async {
        guard let author = currentUser.author else { return }
        
        isRedeeming = true
        
        do {
            let success = try await nutzapService.receiveNutzap(
                nutzap,
                into: wallet,
                author: author
            )
            
            if success {
                await MainActor.run {
                    isRedeeming = false
                    onRedeemed()
                }
            }
        } catch {
            await MainActor.run {
                isRedeeming = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}