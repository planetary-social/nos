//
//  NoteParser.swift
//  Nos
//
//  Created by Martin Dutra on 17/4/23.
//

import CoreData
import Foundation
import RegexBuilder

/// This struct encapsulates the algorithms that parse notes and the mentions inside the note.
struct NoteParser {

    /// Parses attributed text generated when composing a note and returns
    /// the content and tags.
    func parse(attributedText: AttributedString) -> (String, [[String]]) {
        cleanLinks(in: attributedText)
    }

    // swiftlint:disable function_body_length
    /// Parses the content and tags stored in a note and returns an attributed text that can be used for displaying
    /// the note in the UI.
    func parse(content: String, tags: [[String]], context: NSManagedObjectContext) -> AttributedString {
        // swiftlint:disable opening_brace
        let regex = /(?:^|\s)#\[(?<index>\d+)\]|(?:^|\s)(?:nostr:)(?<npub>[-a-zA-Z0-9@:%._\+~#=]{2,256})/
        // swiftlint:enable opening_brace
        let result = content.replacing(regex) { match in
            let substring = match.0
            let index = match.1
            let npub = match.2
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
            } else if let npub {
                let string = String(npub)
                if string.prefix(4) == "npub", let publicKey = PublicKey(npub: string) {
                    return findAndReplaceAuthorReference(publicKey.hex)
                } else if string.prefix(8) == "nprofile", let profile = NProfile(nprofile: string) {
                    return findAndReplaceAuthorReference(profile.publicKeyHex)
                }
            }
            return String(substring)
        }

        let linkedString = (try? result.findAndReplaceUnformattedLinks(in: result)) ?? result

        do {
            return try AttributedString(
                markdown: linkedString,
                options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
            )
        } catch {
            return AttributedString(stringLiteral: content)
        }
    }
    // swiftlint:enable function_body_length

    private func cleanLinks(in attributedString: AttributedString, tags: [[String]] = []) -> (String, [[String]]) {
        var mutableAttributedString = attributedString
        for attributedRun in mutableAttributedString.runs {
            if let link = attributedRun.attributes.link {
                var mutableAttributes = attributedRun.attributes
                mutableAttributes.link = nil
                mutableAttributedString.replaceSubrange(
                    attributedRun.range,
                    with: AttributedString("\(link.absoluteString)", attributes: mutableAttributes)
                )
                if link.scheme == "nostr" {
                    let components = URLComponents(url: link, resolvingAgainstBaseURL: false)
                    if let npub = components?.path, let publicKey = PublicKey(npub: npub) {
                        return cleanLinks(
                            in: mutableAttributedString,
                            tags: tags + [["p", publicKey.hex]]
                        )
                    } else {
                        return cleanLinks(in: mutableAttributedString, tags: tags)
                    }
                } else {
                    return cleanLinks(in: mutableAttributedString, tags: tags)
                }
            }
        }
        return (String(attributedString.characters), tags)
    }
}
