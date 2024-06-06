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
            let firstPathComponent = components.path
            // swiftlint:disable:next opening_brace 
            let unformattedRegex = /(?:nostr:)?(?<entity>((npub1|note1|nprofile1|nevent1)[a-zA-Z0-9]{58,255}))/
            do {
                if let match = try unformattedRegex.firstMatch(in: firstPathComponent) {
                    let entity = match.1
                    let string = String(entity)
                    
                    let (humanReadablePart, checksum) = try Bech32.decode(string)
                    
                    if humanReadablePart == Nostr.publicKeyPrefix, let hex = SHA256Key.decode(base5: checksum) {
                        router.push(authorWithID: hex)
                    } else if humanReadablePart == Nostr.notePrefix, let hex = SHA256Key.decode(base5: checksum) {
                        router.push(noteWithID: hex)
                    } else if humanReadablePart == Nostr.profilePrefix, let hex = TLV.decode(checksum: checksum) {
                        router.push(authorWithID: hex)
                    } else if humanReadablePart == Nostr.eventPrefix, let hex = TLV.decode(checksum: checksum) {
                        router.push(noteWithID: hex)
                    } 
                }
            } catch {
                Log.optional(error)
            }
        }
    }
}
