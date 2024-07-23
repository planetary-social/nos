import CoreData
import Foundation
import Logger
import RegexBuilder

/// This struct encapsulates the algorithms that parse notes and the mentions inside the note.
struct NoteParser {

    /// Parses attributed text generated when composing a note and returns
    /// the content and tags.
    func parse(attributedText: AttributedString) -> (String, [[String]]) {
        cleanLinks(in: attributedText)
    }
    
    /// Parses the content and tags stored in a note and returns an attributed text with tagged entities replaced
    /// with readable names.
    func parse(content: String, tags: [[String]], context: NSManagedObjectContext) -> AttributedString {
        var result = replaceTaggedNostrEntities(in: content, tags: tags, context: context)
        result = replaceNostrEntities(in: result)
        do {
            return try AttributedString(
                markdown: result,
                options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
            )
        } catch {
            return AttributedString(stringLiteral: content)
        }
    }

    /// Parses the content and tags stored in a note and returns an attributed string and list of URLs that can be used 
    /// to display the note in the UI.
    func parse(content: String, tags: [[String]], context: NSManagedObjectContext) -> (AttributedString, [URL]) {
        let (cleanedString, urls) = URLParser().replaceUnformattedURLs(
            in: content
        )
        var result = replaceTaggedNostrEntities(in: cleanedString, tags: tags, context: context)
        result = replaceNostrEntities(in: result)
        do {
            return (try AttributedString(
                markdown: result,
                options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
            ), urls)
        } catch {
            return (AttributedString(stringLiteral: content), urls)
        }
    }

    // swiftlint:disable function_body_length
    /// Replaces tagged references like #[0] or nostr:npub1... with markdown links
    private func replaceTaggedNostrEntities(
        in content: String,
        tags: [[String]],
        context: NSManagedObjectContext
    ) -> String {
        // swiftlint:disable:next opening_brace
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

    /// Replaces Nostr entities embedded in the note (without a proper tag) with markdown links
    private func replaceNostrEntities(in content: String) -> String {
        let unformattedRegex =
            /(?:^|\s)@?(?:nostr:)?(?<entity>((npub1|note1|nprofile1|nevent1|naddr1)[a-zA-Z0-9]{58,}))/
        // swiftlint:disable:previous opening_brace

        return content.replacing(unformattedRegex) { match in
            let substring = match.0
            let entity = match.1
            var prefix = ""
            let firstCharacter = String(String(substring).prefix(1))
            if firstCharacter.range(of: #"\s|\r\n|\r|\n"#, options: .regularExpression) != nil {
                prefix = firstCharacter
            }
            let string = String(entity)

            do {
                let identifier = try NostrIdentifier.decode(bech32String: string)
                switch identifier {
                case .npub(let rawAuthorID), .nprofile(let rawAuthorID, _):
                    return "\(prefix)[\(string)](@\(rawAuthorID))"
                case .note(let rawEventID), .nevent(let rawEventID, _, _, _):
                    return "\(prefix)[\(String(localized: .localizable.linkToNote))](%\(rawEventID))"
                case .naddr(let replaceableID, _, let authorID, let kind):
                    return "\(prefix)[\(String(localized: .localizable.linkToNote))]" +
                        "($\(replaceableID);\(authorID);\(kind))"
                }
            } catch {
                return String(substring)
            }
        }
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
