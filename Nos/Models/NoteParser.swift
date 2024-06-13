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

    // swiftlint:disable function_body_length superfluous_disable_command
    /// Replaces tagged references like #[0] or nostr:npub1... with markdown links
    private func replaceTaggedNostrEntities(
        in content: String,
        tags: [[String]],
        context: NSManagedObjectContext
    ) -> String {
        // swiftlint:disable opening_brace operator_usage_whitespace closure_spacing comma
        let regex = /(?:^|\s)#\[(?<index>\d+)\]|(?:^|\s)@?(?:nostr:)(?<npubornprofile>[a-zA-Z0-9]{2,256})/
        // swiftlint:enable opening_brace operator_usage_whitespace closure_spacing comma
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
                    let (humanReadablePart, checksum) = try Bech32.decode(string)
                    if humanReadablePart == Nostr.publicKeyPrefix, let hex = SHA256Key.decode(base5: checksum) {
                        return findAndReplaceAuthorReference(hex)
                    } else if humanReadablePart == Nostr.profilePrefix, let hex = TLV.decode(checksum: checksum) {
                        return findAndReplaceAuthorReference(hex)
                    }
                } catch {
                    return String(substring)
                }
            }
            
            try? context.saveIfNeeded()
            return String(substring)
        }
    }
    // swiftlint:enable function_body_length superfluous_disable_command

    /// Replaces Nostr entities embedded in the note (without a proper tag) with markdown links
    private func replaceNostrEntities(in content: String) -> String {
        // swiftlint:disable opening_brace operator_usage_whitespace closure_spacing comma superfluous_disable_command
        let unformattedRegex = /(?:^|\s)@?(?:nostr:)?(?<entity>((npub1|note1|nprofile1|nevent1)[a-zA-Z0-9]{58,255}))/
        // swiftlint:enable opening_brace operator_usage_whitespace closure_spacing comma superfluous_disable_command

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
                let (humanReadablePart, checksum) = try Bech32.decode(string)

                if humanReadablePart == Nostr.publicKeyPrefix, let hex = SHA256Key.decode(base5: checksum) {
                    return "\(prefix)[\(string)](@\(hex))"
                } else if humanReadablePart == Nostr.notePrefix, let hex = SHA256Key.decode(base5: checksum) {
                    return "\(prefix)[\(String(localized: .localizable.linkToNote))](%\(hex))"
                } else if humanReadablePart == Nostr.profilePrefix, let hex = TLV.decode(checksum: checksum) {
                    return "\(prefix)[\(string)](@\(hex))"
                } else if humanReadablePart == Nostr.eventPrefix, let hex = TLV.decode(checksum: checksum) {
                    return "\(prefix)[\(String(localized: .localizable.linkToNote))](%\(hex))"
                } else {
                    return String(substring)
                }
            } catch {
                return String(substring)
            }
        }
    }

    private func cleanLinks(
        in attributedString: AttributedString,
        tags: [[String]] = []
    ) -> (String, [[String]]) {
        var attributedString = attributedString
        let runs = attributedString.runs
        let isLink = { (run: AttributedString.Runs.Run) in
            run.link != nil
        }
        var links: [AttributedString.Runs.Run] = runs.filter(isLink).reversed()
        guard let firstRun = links.popLast(), let link = firstRun.link else {
            return (String(attributedString.characters), tags)
        }
        var attributes = firstRun.attributes
        var range = firstRun.range
        while let nextRun = links.popLast(),
              nextRun.range.lowerBound == firstRun.range.upperBound,
              nextRun.link == firstRun.link {
            range = range.lowerBound..<nextRun.range.upperBound
            attributes.merge(nextRun.attributes)
        }
        attributes.link = nil
        attributedString.replaceSubrange(
            range,
            with: AttributedString(
                "\(link.absoluteString)",
                attributes: attributes
            )
        )
        if link.scheme == "nostr" {
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
            return cleanLinks(in: attributedString, tags: tags)
        }
    }
}
