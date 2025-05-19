import CoreData
import Foundation
import Logger
import RegexBuilder

/// This struct encapsulates the algorithms that parse notes and the mentions inside the note.
struct NoteParser {

    /// Components of a note that can be used to display the note in the UI.
    struct NoteDisplayComponents {
        /// The note content as attributed text with tagged entities replaced with readable names.
        let attributedContent: AttributedString
        /// Content links parsed from the note.
        let contentLinks: [URL]
        /// The id of the first quoted note in the content, if one exists.
        let quotedNoteID: RawEventID?
    }
    
    /// Parses attributed text generated when composing a note and returns
    /// the content and tags.
    func parse(attributedText: AttributedString) -> (String, [[String]]) {
        let (content, tags) = cleanLinks(in: attributedText)
        let hashtags = hashtags(in: content)
        return (content, tags + hashtags)
    }

    func hashtags(in content: String) -> [[String]] {
        let pattern = "(?<=^|\\s)#([a-zA-Z0-9]{2,256})(?=\\s|[.,!?;:]|$)"
        let regex = try! NSRegularExpression(pattern: pattern) // swiftlint:disable:this force_try
        let matches = regex.matches(in: content, range: NSRange(content.startIndex..., in: content))

        let hashtags = matches.map { match -> [String] in
            if let range = Range(match.range(at: 1), in: content) {
                return ["t", String(content[range].lowercased())]
            }
            return []
        }

        return hashtags
    }

    /// Parses the content and tags stored in a note and returns an attributed text with tagged entities replaced
    /// with readable names.
    func parse(content: String, tags: [[String]], context: NSManagedObjectContext) -> AttributedString {
        let replaced = replaceTaggedNostrEntities(in: content, tags: tags, context: context)
        let (result, _) = replaceNostrEntities(in: replaced)
        return (try? AttributedString(
            markdown: result,
            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(content)
    }
    
    /// Parses the content and tags stored in a note and returns components that can be used
    /// to display the note in the UI.
    func components(from content: String, tags: [[String]], context: NSManagedObjectContext) -> NoteDisplayComponents {
        let (cleanedString, urls) = URLParser().replaceUnformattedURLs(
            in: content
        )
        let replaced = replaceTaggedNostrEntities(in: cleanedString, tags: tags, context: context)
        let (result, quotedNoteID) = replaceNostrEntities(in: replaced, capturesFirstNote: true)
        
        let attributedContent = (try? AttributedString(
            markdown: result.trimmingCharacters(in: .whitespacesAndNewlines),
            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(content)
        return NoteDisplayComponents(
            attributedContent: attributedContent,
            contentLinks: urls,
            quotedNoteID: quotedNoteID
        )
    }

    // swiftlint:disable function_body_length
    /// Replaces tagged references like #[0] or nostr:npub1... with markdown links
    private func replaceTaggedNostrEntities(
        in content: String,
        tags: [[String]],
        context: NSManagedObjectContext
    ) -> String {
        let regex = /(?:^|\s)#\[(?<index>\d+)\]|(?:^|\s)@?(?:nostr:)(?<npubornprofile>[a-zA-Z0-9]{2,256})/
        return content.replacing(regex) { match in
            let substring = match.0
            let index = match.1
            let npubOrNProfile = match.2
            var prefix = ""
            let firstCharacter = String(String(substring).prefix(1))
            if firstCharacter.range(of: #"\s|\r\n|\r|\n"#, options: .regularExpression) != nil {
                prefix = firstCharacter
            }
            let findAndReplaceAuthorReference: (String) -> String = { hex in
                context.performAndWait {
                    if let author = try? Author.findOrCreate(by: hex, context: context) {
                        return "\(prefix)[@\(author.safeName)](@\(hex))"
                    } else {
                        return "\(prefix)[@\(hex)](@\(hex))"
                    }
                }
            }
            let findAndReplaceEventReference: (String) -> String = { hex in
                context.performAndWait {
                    if let event = try? Event.findOrCreateStubBy(id: hex, context: context),
                        let bech32NoteID = event.bech32NoteID {
                        return "\(prefix)[@\(bech32NoteID)](%\(hex))"
                    } else {
                        return "\(prefix)[@\(hex)](%\(hex))"
                    }
                }
            }
            if let index, let index = Int(String(index)) {
                if let tag = tags[safe: index], let type = tag[safe: 0], let hex = tag[safe: 1] {
                    if type == "p" {
                        return findAndReplaceAuthorReference(hex)
                    } else if type == "e" {
                        return findAndReplaceEventReference(hex)
                    }
                }
            } else if let npubOrNProfile {
                let string = String(npubOrNProfile)
                do {
                    let identifier = try NostrIdentifier.decode(bech32String: string)
                    switch identifier {
                    case .npub(let rawAuthorID), .nprofile(let rawAuthorID, _):
                        return findAndReplaceAuthorReference(rawAuthorID)
                    default:
                        break
                    }
                } catch {
                    return String(substring)
                }
            }
            
            try? context.saveIfNeeded()
            return String(substring)
        }
    }
    // swiftlint:enable function_body_length

    /// Replaces Nostr entities embedded in the note (without a proper tag) with markdown links and
    /// optionally extracts the first quoted note id. This function ensures all nevent identifiers get the 
    /// "nostr:" prefix in the markdown URL, according to NIP-01 standards.
    ///
    /// - Parameters:
    ///   - content: The note content in which to replace entities.
    ///   - capturesFirstNote: If true, this function will extract the first quoted note id, if it exists.
    ///                        Defaults to `false`.
    /// - Returns: A tuple of the edited content and the first quoted note id, if it was requested and it exists.
    func replaceNostrEntities(in content: String, capturesFirstNote: Bool = false) -> (String, RawEventID?) {
        // Note: This pattern contains a lookbehind, which is not currently supported by the newer Swift regex syntax.
        // The pattern matches Nostr entities with or without the "nostr:" prefix 
        let pattern = "(?<=^|\\s|[^:\\/])@?(?:nostr:)?((npub1|note1|nprofile1|nevent1|naddr1)[a-zA-Z0-9]{58,})"
        let regex = try! NSRegularExpression(pattern: pattern, options: []) // swiftlint:disable:this force_try
        
        var firstNoteID: RawEventID?
        
        let result = regex.stringByReplacingMatches(
            in: content,
            options: [],
            range: NSRange(location: 0, length: content.utf16.count)
        ) { match in
            let nsRange = match.range(at: 0)
            guard let range = Range(nsRange, in: content) else { return "" }
            let substring = String(content[range])
            
            let entityRange = match.range(at: 1)
            guard let entityRange = Range(entityRange, in: content) else { return substring }
            let entity = String(content[entityRange])
            
            var prefix = ""
            let firstCharacter = String(substring.prefix(1))
            if firstCharacter.range(of: #"\s|\r\n|\r|\n"#, options: .regularExpression) != nil {
                prefix = firstCharacter
            }
            
            do {
                let identifier = try NostrIdentifier.decode(bech32String: entity)
                switch identifier {
                case .npub(let rawAuthorID), .nprofile(let rawAuthorID, _):
                    return "\(prefix)[\(entity)](@\(rawAuthorID))"
                case .note(let rawEventID), .nevent(let rawEventID, _, _, _):
                    if capturesFirstNote && firstNoteID == nil {
                        firstNoteID = rawEventID
                        return ""
                    } else {
                        // Always ensure we have exactly one "nostr:" prefix
                        return "\(prefix)[\(String(localized: .localizable.linkToNote))](nostr:%\(rawEventID))"
                    }
                case .naddr(let replaceableID, _, let authorID, let kind):
                    return "\(prefix)[\(String(localized: .localizable.linkToNote))]" +
                    "($\(replaceableID);\(authorID);\(kind))"
                case .nsec:
                    return substring
                }
            } catch {
                return substring
            }
        }
        
        return (result, firstNoteID)
    }

    /// Parse links in `attributedString` and replace them with plain text,
    /// adding tags if they are nostr: links (in other words, mentions to other
    /// users).
    ///
    /// - parameter attributedString: An AttributedString instance with the post
    /// - parameter tags: The current list of tags
    /// - returns: The note content and the generated tags
    ///
    /// This function is recursive, it just process the first link it finds, and
    /// then recurses itself until there are no more links to process.
    private func cleanLinks(
        in attributedString: AttributedString,
        tags: [[String]] = []
    ) -> (String, [[String]]) {
        var attributedString = attributedString
        let runs = attributedString.runs

        // Find the first link in the attributed string
        let isLink = { (attributedRun: AttributedString.Runs.Run) in
            attributedRun.link != nil
        }
        var links: [AttributedString.Runs.Run] = runs.filter(isLink).reversed()
        guard let firstRun = links.popLast(), let link = firstRun.link else {
            // No links found, just return the result
            return (String(attributedString.characters), tags)
        }
        var attributes = firstRun.attributes

        // Look if there are consecutive links and merge the ranges
        var range = firstRun.range
        while let nextRun = links.popLast(),
            nextRun.range.lowerBound == range.upperBound,
            nextRun.link == firstRun.link {
            range = range.lowerBound..<nextRun.range.upperBound
            attributes.merge(nextRun.attributes)
        }

        // Replace the link with just plain text so we parse the next link the
        // next time we do a recursion (until there are no more links to parse.
        attributes.link = nil
        attributedString.replaceSubrange(
            range,
            with: AttributedString(
                "\(link.absoluteString)",
                attributes: attributes
            )
        )
        if link.scheme == "nostr" {
            // It is a nostr link, continue with the recursion while adding the
            // corresponding tag
            let components = URLComponents(url: link, resolvingAgainstBaseURL: false)
            if let npub = components?.path, let publicKey = PublicKey(npub: npub) {
                return cleanLinks(
                    in: attributedString,
                    tags: tags + [["p", publicKey.hex]]
                )
            } else {
                return cleanLinks(in: attributedString, tags: tags)
            }
        } else {
            // Just a normal link, continue with the recursion without adding a
            // tag
            return cleanLinks(in: attributedString, tags: tags)
        }
    }
}
