// ABOUTME: Badge view showing if a user accepts nutzaps and their preferred mints
// ABOUTME: Displayed in profile header to indicate nutzap receiving capability

import SwiftUI
import CoreData

struct NutzapBadgeView: View {
    let author: Author
    
    @Environment(\.managedObjectContext) private var viewContext
    @State private var acceptsNutzaps = false
    @State private var preferredMints: [String] = []
    
    private var mintCount: Int {
        preferredMints.count
    }
    
    var body: some View {
        if acceptsNutzaps {
            HStack(spacing: 6) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.orange)
                
                Text("Accepts Nutzaps")
                    .font(.clarity(.medium, textStyle: .caption))
                    .foregroundColor(.orange)
                
                if mintCount > 0 {
                    Text("• \(mintCount) \(mintCount == 1 ? "mint" : "mints")")
                        .font(.clarity(.regular, textStyle: .caption))
                        .foregroundColor(.secondaryTxt)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.orange.opacity(0.1))
            .clipShape(Capsule())
        }
        .task {
            await checkNutzapStatus()
        }
    }
    
    private func checkNutzapStatus() async {
        guard let pubkey = author.hexadecimalPublicKey else { return }
        
        let request = NSFetchRequest<Event>(entityName: "Event")
        request.predicate = NSPredicate(
            format: "author == %@ AND kind == %d",
            author,
            EventKind.nutzapInfo.rawValue
        )
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        request.fetchLimit = 1
        
        do {
            let nutzapInfoEvents = try viewContext.fetch(request)
            
            if let latestInfo = nutzapInfoEvents.first,
               let tags = latestInfo.allTags as? [[String]] {
                
                // Extract mints
                let mints = tags.compactMap { tag -> String? in
                    if tag.count >= 2 && tag[0] == "mint" {
                        return tag[1]
                    }
                    return nil
                }
                
                await MainActor.run {
                    self.acceptsNutzaps = !mints.isEmpty
                    self.preferredMints = mints
                }
            }
        } catch {
            print("Failed to check nutzap status: \(error)")
        }
    }
}

#Preview {
    let previewData = PreviewData()
    return NutzapBadgeView(author: previewData.alice)
        .environment(\.managedObjectContext, previewData.viewContext)
        .padding()
}