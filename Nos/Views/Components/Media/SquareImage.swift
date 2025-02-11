import SwiftUI
import SDWebImageSwiftUI

struct SquareImage: View {
    let url: URL
    
    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                WebImage(url: url)
                    .resizable()
                    .indicator(.activity)
                    .aspectRatio(contentMode: .fill)
            }
            .clipShape(Rectangle())
    }
}
