import Foundation
import Logger
import Dependencies

enum DeepLinkService {
    
    /// Returns the URL scheme for Nos, which varies by build (dev, staging, production). 
    static var nosURLScheme: String? = { 
        if let urlTypes = Bundle.main.infoDictionary?["CFBundleURLTypes"] as? [[String: Any]] {
            for urlTypeDictionary in urlTypes {
                guard let urlSchemes = urlTypeDictionary["CFBundleURLSchemes"] as? [String] else { continue }
                guard let externalURLScheme = urlSchemes.first else { continue }
                return externalURLScheme
            }
        }
        
        return nil
    }()
    
    @MainActor static func handle(_ url: URL, router: Router) {
        @Dependency(\.persistenceController) var persistenceController
        @Dependency(\.router) var router
        Log.info("handling link \(url.absoluteString)")
        
        let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        
        guard let components, let nosURLScheme, components.scheme == nosURLScheme else {
            return
        }
        
        if components.host == "note", components.path == "/new" {
            let noteContents = components
                .queryItems?
                .first(where: { $0.name == "contents" })?
                .value
            
            router.showNewNoteView(contents: noteContents)
        } else {
            /// Check for links like nos:nevent123174
            guard let host = components.host else {
                Log.debug("No host in `nos:` deep link; cannot open. URLComponents: \(components)")
                return
            }
            // swiftlint:disable:next opening_brace
            let unformattedRegex = /(?:nostr:)?(?<entity>((npub1|note1|nprofile1|nevent1)[a-zA-Z0-9]{58,}))/
            do {
                if let match = try unformattedRegex.firstMatch(in: host) {
                    let entity = match.1
                    let string = String(entity)

                    let metadata = try NostrMetadata.decode(bech32String: string)
                    switch metadata {
                    case .npub(let rawAuthorID), .nprofile(let rawAuthorID, _):
                        router.pushAuthor(id: rawAuthorID)
                    case .note(let rawEventID), .nevent(let rawEventID, _, _, _):
                        router.pushNote(id: rawEventID)
                    case .naddr:
                        break
                    }
                }
            } catch {
                Log.optional(error)
            }
        }
    }
}
