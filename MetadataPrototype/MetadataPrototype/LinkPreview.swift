import SwiftUI
import LinkPresentation

struct LinkPreview: View {
    let url: URL
    var showUrl: Bool = true
    var showTitle: Bool = true

    @State private var image: UIImage? = nil
    @State private var title: String = ""

    var body: some View {
        VStack(alignment: .center) {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 160)
//                    .frame(width: 200, height: 120)
//                    .clipped()
            } else {
                ProgressView()
                    .frame(height: 160)
            }
            if showUrl || showTitle {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        if showTitle {
                            Text(title)
                                .font(.title3)
                                .bold()
                        }
                        if showUrl {
                            Text(url.absoluteString)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                    Spacer()
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.purple)
            }
        }
        .background(.black)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding()
        .onAppear(perform: fetchLinkPreview)
    }

    private func fetchLinkPreview() {
        let metadataProvider = LPMetadataProvider()
        metadataProvider.startFetchingMetadata(for: url) { metadata, error in
            guard let metadata = metadata, error == nil else {
                print("Failed to fetch metadata: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            metadata.imageProvider?.loadObject(ofClass: UIImage.self) { image, error in
                if let image = image as? UIImage {
                    DispatchQueue.main.async {
                        self.image = image
                    }
                } else {
                    print("Failed to load image: \(error?.localizedDescription ?? "Unknown error")")
                }
            }

            DispatchQueue.main.async {
                self.title = metadata.title ?? ""
            }
        }
    }
}

#Preview {
    ScrollView {
        VStack {
            LinkPreview(url: URL(string: "https://arstechnica.com/space/2024/03/its-a-few-years-late-but-a-prototype-supersonic-airplane-has-taken-flight/")!)
            LinkPreview(url: URL(string: "https://image.nostr.build/ce70e9c25fdf90405ff598c45db9cdf6d3bbac12a72c35495f95cd01e2ed6c07.jpg")!, showUrl: false, showTitle: false)
            LinkPreview(url: URL(string: "https://glass.photo/jtbrown/zY8mJtzwnT3tQlMyVvyUs")!)
            LinkPreview(url: URL(string: "https://www.macrumors.com/2024/03/23/relocated-apple-square-one-opens/")!)
            LinkPreview(url: URL(string: "https://www.swiftuifieldguide.com/layout/safe-area/")!)
        }
    }
}

struct ContentView: View {
    let urls = [
        URL(string: "https://www.macrumors.com/2024/03/23/relocated-apple-square-one-opens/")!,
        URL(string: "https://www.apple.com")!,
        // Add more URLs as needed
    ]

    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                ForEach(urls.indices, id: \.self) { index in
                    LinkPreview(url: urls[index])
                        .frame(maxWidth: .infinity)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .never))

            VStack {
                Spacer()
                HStack {
                    ForEach(urls.indices, id: \.self) { index in
                        Circle()
                            .fill(index == selectedTab ? Color.white : Color.gray)
                            .frame(width: 10, height: 10)
                            .onTapGesture {
                                withAnimation {
                                    selectedTab = index
                                }
                            }
                    }
                }
                .padding(.top, -20)
            }
        }
    }
}
#Preview {
    ContentView()
        .frame(height: 250)
}
