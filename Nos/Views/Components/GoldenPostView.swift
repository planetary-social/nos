import SwiftUI
import Dependencies

let goldenRatio: CGFloat = 0.618

struct GoldenPostView: View {

    @ObservedObject var author: Author
    @ObservedObject var note: Event

    @EnvironmentObject private var router: Router

    @State private var noteContent = LoadingContent<AttributedString>.loading

    @Dependency(\.persistenceController) private var persistenceController
    @Dependency(\.urlParser) private var urlParser

    internal init(author: Author, note: Event) {
        self.author = author
        self.note = note
    }

    var noteText: some View {
        Group {
            switch noteContent {
            case .loading:
                Text(note.content ?? "").redacted(reason: .placeholder)
            case .loaded(let attributedString):
                Text(attributedString)
            }
        }
    }

    var text: some View {
        noteText
            .foregroundColor(.primaryTxt)
            .tint(.accent)
            .multilineTextAlignment(.leading)
            .handleURLsInRouter()
    }

    var footer: some View {
        HStack(alignment: .center) {
            Button {
                router.push(author)
            } label: {
                HStack(alignment: .center) {
                    AvatarView(imageUrl: author.profilePhotoURL, size: 20)
                    // if !post.isBlobOnly {
                    Text(author.safeName)
                        .lineLimit(1)
                        .font(.clarity(.regular, textStyle: .subheadline))
                        .foregroundColor(Color.secondaryTxt)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    // }
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(10)
        .task {
            let backgroundContext = persistenceController.backgroundViewContext
            let parsedAttributedContent = await Event.attributedContent(
                noteID: note.identifier,
                context: backgroundContext
            )
            withAnimation(.easeIn(duration: 0.1)) {
                self.noteContent = .loaded(parsedAttributedContent)
            }
        }
    }

    var isTextOnly: Bool {
        if let content = note.content {
            return (try? urlParser.findUnformattedURLs(in: content).count) == 0
        } else {
            return true
        }
    }

    var firstImageURL: URL? {
        guard let content = note.content else {
            return nil
        }
        return try? urlParser.findUnformattedURLs(
            in: content
        )
        .first(where: { $0.isImage })
    }

    var imageView: some View {
        Group {
            if let url = firstImageURL {
                SquareImage(url: url)
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            imageView
            
            VStack {
                HStack {
                    if isTextOnly {
                        text
                            .padding(EdgeInsets(top: 15, leading: 10, bottom: 15, trailing: 10))
                    } else {
                        text
                            .padding(EdgeInsets(top: 8, leading: 10, bottom: 0, trailing: 10))
                    }
                    Spacer()
                }
                footer
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .aspectRatio(goldenRatio, contentMode: ContentMode.fill)
    }
}

struct GoldenPostView_Previews: PreviewProvider {
    
    static var persistenceController = PersistenceController.preview
    static var previewContext = persistenceController.viewContext
    
    static var shortNote: Event {
        let note = Event(context: previewContext)
        note.content = "Hello, world!"
        return note
    }
    
    static var previewAuthor = Author(context: previewContext)
    
    static var longNote: Event {
        let note = Event(context: previewContext)
        note.content = .loremIpsum(5)
        let author = Author(context: previewContext)
        // TODO: derive from private key
        author.hexadecimalPublicKey = "32730e9dfcab797caf8380d096e548d9ef98f3af3000542f9271a91a9e3b0001"
        note.author = author
        note.author?.profilePhotoURL = URL(string: "https://avatars.githubusercontent.com/u/1165004?s=40&v=4")
        return note
    }
    
    static var imageNote: Event {
        let note = Event(context: previewContext)
        note.content = "Hello, world!https://cdn.ymaws.com/nacfm.com/resource/resmgr/images/blog_photos/footprints.jpg"
        return note
    }
    
    static var verticalImageNote: Event {
        let note = Event(context: previewContext)
        // swiftlint:disable line_length
        note.content = "Hello, world!https://nostr.build/i/nostr.build_1b958a2af7a2c3fcb2758dd5743912e697ba34d3a6199bfb1300fa6be1dc62ee.jpeg"
        // swiftlint:enable line_length
        return note
    }
    
    static var veryWideImageNote: Event {
        let note = Event(context: previewContext)
        // swiftlint:disable line_length
        note.content = "Hello, world! https://nostr.build/i/nostr.build_db8287dde9aedbc65df59972386fde14edf9e1afc210e80c764706e61cd1cdfa.png"
        // swiftlint:enable line_length
        return note
    }
    
    static var previews: some View {
        Group {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible())], spacing: 10) {
                Group {
                    GoldenPostView(author: previewAuthor, note: imageNote)
                    GoldenPostView(author: previewAuthor, note: shortNote)
                    GoldenPostView(author: previewAuthor, note: longNote)
                    GoldenPostView(author: previewAuthor, note: verticalImageNote)
                    GoldenPostView(author: previewAuthor, note: veryWideImageNote)
                    GoldenPostView(author: previewAuthor, note: longNote)
                }
                .background(Color.previewBg)
            }
            VStack {
                GoldenPostView(author: previewAuthor, note: shortNote)
                GoldenPostView(author: previewAuthor, note: longNote)
            }
            .preferredColorScheme(.dark)
        }
        .padding(10)
        .background(Color.appBg)
    }
}
