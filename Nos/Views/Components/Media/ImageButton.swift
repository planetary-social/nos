import SDWebImageSwiftUI
import SwiftUI

/// A button that's filled entirely with an image and presents an `ImageViewer` when tapped.
struct ImageButton: View {
    /// The URL of the image to display as the button label.
    let url: URL
    
    /// Whether the image viewer is presented or not.
    @State private var isViewerPresented = false

    @State private var image: PlatformImage?

    var body: some View {
//        workingWebImage
//        rectangularImage
        frameImage
    }

    var frameImage: some View {
        Button {
            isViewerPresented = true
        } label: {
            WebImage(url: url)
                .resizable()
                .indicator(.activity)
                .aspectRatio(contentMode: .fill)
                .frame(
                    minWidth: 0,
                    maxWidth: .infinity,
                    minHeight: 0,
                    maxHeight: .infinity
                )
                .aspectRatio(4 / 3, contentMode: .fit)
                .clipShape(.rect)
        }
        .sheet(isPresented: $isViewerPresented) {
            ImageViewer(url: url)
        }
    }

    var rectangularImage: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                WebImage(url: url)
                    .resizable()
                    .indicator(.activity)
                    .aspectRatio(contentMode: .fill)
                    .onTapGesture {
                        isViewerPresented = true
                    }
            }
        .clipShape(Rectangle())
    }

    var workingWebImage: some View {
        GeometryReader { proxy in
            WebImage(url: url)
                .onSuccess { image, _, _ in
                    self.image = image
                }
                .resizable()
                .indicator(.activity)
                .aspectRatio(contentMode: .fill)
                .frame(width: proxy.size.width, height: proxy.size.width * 3 / 4)
                .clipped()
                .sheet(isPresented: $isViewerPresented) {
                    ImageViewer(url: url)
                }
        }
    }

    @ViewBuilder var workingImage: some View {
        if let image {
            GeometryReader { proxy in
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: proxy.size.width, height: proxy.size.width * 3 / 4)
                    .clipped()
            }
        } else {
            EmptyView()
        }
    }

    @ViewBuilder var triedABunchOfThingsImage: some View {
        if let image {
            GeometryReader { proxy in
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                //                .aspectRatio(contentMode: .fit)
                //                .scaledToFit()
                //                    .aspectRatio(CGSize(width: 4, height: 3), contentMode: .fill)
                    .frame(width: proxy.size.width, height: proxy.size.width * 3 / 4)
                    .clipped()
                //                .clipShape(
                //                    Rectangle()
                //                        .aspectRatio(CGSize(width: 4, height: 3), contentMode: .fill)
                //                )
            }
        } else {
            EmptyView()
        }
    }
}

#Preview {
    ImageButton(
        url: URL(
            string: "https://images.unsplash.com/photo-1723160004469-1b34c81272f3"
        )!
    )
}

#Preview {
    ImageButton(
        url: URL(
            string: "https://images.unsplash.com/photo-1715686529501-e097bd9caea7"
        )!
    )
}

#Preview {
    ImageButton(
        url: URL(
            string: "https://image.nostr.build/9640e78f03afc4927d80a15fd1c4bd1404dc654a8663efb92cc9ee1b8b0719a3.jpg"
        )!
    )
}
