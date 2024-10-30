import Foundation
import Logger
import Dependencies

enum DeepLinkService {
    
    /// Returns the URL schemes that Nos supports. Dev, Staging, and Production builds each have their own scheme,
    /// and all of them also support the `nostr:` scheme.
    static var supportedURLSchemes: [String] = {
        if let urlTypes = Bundle.main.infoDictionary?["CFBundleURLTypes"] as? [[String: Any]] {
            for urlTypeDictionary in urlTypes {
                guard let urlSchemes = urlTypeDictionary["CFBundleURLSchemes"] as? [String] else { continue }
                return urlSchemes
            }
        }
        
        return []
    }()
    
    @MainActor static func handle(_ url: URL, router: Router) {
        @Dependency(\.persistenceController) var persistenceController
        @Dependency(\.currentUser) var currentUser
        Log.info("handling link \(url.absoluteString)")
        
        let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        
        guard let components,
            let scheme = components.scheme,
            supportedURLSchemes.contains(scheme) else {
            return
        }
        
        if components.host == "note", components.path == "/new" {
            let noteContents = components
                .queryItems?
                .first(where: { $0.name == "contents" })?
                .value
            
            router.showNoteComposer(contents: noteContents)
        } else {
            // The destination (npub, note, nprofile, nevent, or naddr) may be in the host or the path.
            // If the URL looks like nos://npub1..., we want the host. If it's nostr:npub1..., the path is what we want.
            let destination = components.host ?? components.path
            let unformattedRegex = /(?:nostr:)?(?<entity>((npub1|note1|nprofile1|nevent1|naddr1)[a-zA-Z0-9]{58,}))/
            do {
                if let match = try unformattedRegex.firstMatch(in: destination) {
                    let entity = match.1
                    let string = String(entity)

                    let identifier = try NostrIdentifier.decode(bech32String: string)
                    switch identifier {
                    case .npub(let rawAuthorID), .nprofile(let rawAuthorID, _):
                        let author = try Author.findOrCreate(
                            by: rawAuthorID,
                            context: persistenceController.viewContext
                        )
                        Task { try await currentUser.follow(author: author) }
                        router.pushAuthor(id: rawAuthorID)
                    case .note(let rawEventID), .nevent(let rawEventID, _, _, _):
                        router.pushNote(id: rawEventID)
                    case .naddr(let replaceableID, _, let authorID, let kind):
                        router.pushNote(
                            replaceableID: replaceableID,
                            authorID: authorID,
                            kind: Int64(kind)
                        )
                    case .nsec:
                        break
                    }
                }
            } catch {
                Log.optional(error)
            }
        }
    }
}
