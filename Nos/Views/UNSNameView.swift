import SwiftUI

/// Displays a Universal Name with a logo if the user has one.
struct UNSNameView: View {
    
    @ObservedObject var author: Author
    @EnvironmentObject private var relayService: RelayService
    
    var body: some View {
        if !(author.uns ?? "").isEmpty {
            
            Button {
                if let url = relayService.unsURL(from: author.uns ?? "") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack(spacing: 3) {
                    Image.unsLogoLight
                    Text(author.uns ?? "")
                        .foregroundColor(.secondaryTxt)
                        .font(.clarity(.medium, textStyle: .subheadline))
                        .multilineTextAlignment(.leading)
                }
            }
        } else {
            EmptyView()
        }
    }
}
