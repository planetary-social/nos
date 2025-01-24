import SwiftUI
import Logger
import SDWebImageSwiftUI

struct AvatarView: View {
    let imageUrl: URL?
    let size: CGFloat
    private let id: String
    
    init(imageUrl: URL?, size: CGFloat) {
        self.imageUrl = imageUrl
        self.size = size
        self.id = imageUrl?.absoluteString ?? "empty-avatar-\(UUID())"
    }
    
    var body: some View {
        ManagedImageView(imageUrl: imageUrl, size: size, id: id)
    }
}

private struct ManagedImageView: View {
    let imageUrl: URL?
    let size: CGFloat
    let id: String
    
    @StateObject private var loader = ImageLoader()
    
    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color.gray
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .id(id)
        .task(id: imageUrl?.absoluteString) {
            await loader.load(url: imageUrl)
        }
    }
}

private class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    private var cancellable: SDWebImageCombinedOperation?
    
    func load(url: URL?) async {
        await MainActor.run {
            cancel()
        }
        
        guard let url = url else {
            await MainActor.run {
                image = nil
            }
            return
        }
        
        // Check cache first
        if let cachedImage = SDImageCache.shared.imageFromCache(forKey: url.absoluteString) {
            await MainActor.run {
                image = cachedImage
            }
            return
        }
        
        // Load from network
        await withCheckedContinuation { continuation in
            Task { @MainActor in
                cancellable = SDWebImageManager.shared.loadImage(
                    with: url,
                    options: [.retryFailed, .refreshCached],
                    progress: nil
                ) { [weak self] image, _, _, _, _, _ in
                    Task { @MainActor in
                        self?.image = image
                        continuation.resume()
                    }
                }
            }
        }
    }
    
    func cancel() {
        cancellable?.cancel()
        cancellable = nil
    }
    
    deinit {
        cancel()
    }
}

// Make view identity stable
extension ManagedImageView: Equatable {
    static func == (lhs: ManagedImageView, rhs: ManagedImageView) -> Bool {
        lhs.id == rhs.id && lhs.size == rhs.size && lhs.imageUrl == rhs.imageUrl
    }
}

struct AvatarView_Previews: PreviewProvider {
    
    static let avatarURL = URL(string: "https://tinyurl.com/47amhyzz") ?? URL.homeDirectory
    
    static var previews: some View {
        VStack {
            AvatarView(imageUrl: avatarURL, size: 24)
            AvatarView(imageUrl: avatarURL, size: 45)
            AvatarView(imageUrl: avatarURL, size: 87)
        }
        VStack {
            AvatarView(imageUrl: nil, size: 24)
            AvatarView(imageUrl: nil, size: 45)
            AvatarView(imageUrl: nil, size: 87)
        }
    }
}
