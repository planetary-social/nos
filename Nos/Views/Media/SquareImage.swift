import SwiftUI
import SDWebImageSwiftUI

struct SquareImage: View {
    var url: URL
    
    var onTap: (() -> Void)?
    
    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                WebImage(url: url)
                    .resizable()
                    .indicator(.activity)
                    .aspectRatio(contentMode: .fill)
                    .onTapGesture {
                        onTap?()
                    }
            }
            .clipShape(Rectangle())
    }
}
