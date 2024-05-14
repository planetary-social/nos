import Dependencies
import SwiftUI

struct BioView: View {

    @ObservedObject var author: Author

    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var router: Router

    @Dependency(\.noteParser) private var noteParser
    
    @State
    private var shouldShowReadMore = false

    @State
    private var intrinsicSize = CGSize.zero

    @State
    private var truncatedSize = CGSize.zero

    private var bio: String? {
        author.about
    }

    private var isLoading: Bool {
        bio == nil
    }

    private let lineSpacing: CGFloat = 7

    private let lineLimit: Int = 5

    private var parsedBio: AttributedString {
        guard let bio else {
            return AttributedString()
        }
        let (content, _) = noteParser.parse(
            content: bio,
            tags: [[]],
            context: viewContext
        )
        return content
    }

    private var font: Font {
        .clarity(.medium, textStyle: .subheadline)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(parsedBio)
                .font(font)
                .foregroundColor(.primaryTxt)
                .tint(.accent)
                .lineSpacing(lineSpacing)
                .lineLimit(lineLimit)
                .padding(EdgeInsets(top: 0, leading: 18, bottom: 0, trailing: 18))
                .environment(\.openURL, OpenURLAction { url in
                    router.open(url: url, with: viewContext)
                    return .handled
                })
                .background {
                    GeometryReader { geometryProxy in
                        Color.clear.preference(key: TruncatedSizePreferenceKey.self, value: geometryProxy.size)
                    }
                }
                .onPreferenceChange(TruncatedSizePreferenceKey.self) { newSize in
                    if newSize.height > truncatedSize.height {
                        truncatedSize = newSize
                        updateShouldShowReadMore()
                    }
                }
                .background {
                    Text(parsedBio)
                        .font(font)
                        .lineSpacing(lineSpacing)
                        .padding(EdgeInsets(top: 0, leading: 18, bottom: 0, trailing: 18))
                        .fixedSize(horizontal: false, vertical: true)
                        .hidden()
                        .background {
                            GeometryReader { geometryProxy in
                                Color.clear.preference(key: IntrinsicSizePreferenceKey.self, value: geometryProxy.size)
                            }
                        }
                        .onPreferenceChange(IntrinsicSizePreferenceKey.self) { newSize in
                            if newSize.height > intrinsicSize.height {
                                intrinsicSize = newSize
                                updateShouldShowReadMore()
                            }
                        }
                }
            if shouldShowReadMore {
                ZStack(alignment: .center) {
                    Text(String(localized: .localizable.readMore).uppercased())
                        .font(.clarity(.regular, textStyle: .caption1))
                        .foregroundColor(.secondaryTxt)
                        .padding(EdgeInsets(top: 4, leading: 6, bottom: 4, trailing: 6))
                        .background(Color.hashtagBg)
                        .cornerRadius(4)
                }
                .frame(maxWidth: .infinity)
                .padding(EdgeInsets(top: 3, leading: 0, bottom: 1, trailing: 0))
            }
        }
        .placeholder(when: isLoading) {
            Text(String.loremIpsum(1))
                .font(.clarity(.regular))
                .lineSpacing(lineSpacing)
                .lineLimit(5)
                .padding(EdgeInsets(top: 0, leading: 18, bottom: 0, trailing: 18))
                .redacted(reason: .placeholder)
        }
        .padding(0)
    }

    private func updateShouldShowReadMore() {
        shouldShowReadMore = intrinsicSize.height != truncatedSize.height
    }

    fileprivate struct IntrinsicSizePreferenceKey: PreferenceKey {
        static var defaultValue: CGSize = .zero
        static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
    }

    fileprivate struct TruncatedSizePreferenceKey: PreferenceKey {
        static var defaultValue: CGSize = .zero
        static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
    }
}

struct BioView_Previews: PreviewProvider {
    static var previewData = PreviewData()
    static var previews: some View {
        Group {
            BioView(author: previewData.alice)
            BioView(author: previewData.alice)
            BioView(author: previewData.alice)
        }
        .padding()
        .background(Color.previewBg)
    }
}
