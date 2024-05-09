import Foundation
import Logger

/// Parses unformatted urls in a string and replace them with markdown links
struct URLParser {
    /// Returns an array with all unformated urls
    func findUnformattedURLs(in content: String) throws -> [URL] {
        // swiftlint:disable line_length
        let regex = "((http|https)?:\\/\\/.)?(www\\.)?[-a-zA-Z0-9@:%._\\+~#=]{2,256}\\.[a-z]{2,6}\\b([-a-zA-Z0-9@:%_\\+.~#?&//=]*)"
        // swiftlint:enable line_length

        var links = [URL]()
        let regularExpression = try NSRegularExpression(pattern: regex)
        let wholeRange = NSRange(location: 0, length: content.utf16.count)
        for match in regularExpression.matches(in: content, range: wholeRange) {
            let range = Range(match.range, in: content)
            if let range, let url = URL(string: String(content[range])) {
                links.append(url)
            }
        }
        return links
    }

    /// Creates a new string with all URLs and any preceding and trailing
    /// whitespace removed and removed duplicate newlines, and returns the new
    /// string and an array of all the URLs.
    func replaceUnformattedURLs(
        in content: String
    ) -> (String, [URL]) {
        var urls: [URL] = []
        let mutableString = NSMutableString(string: content)

        urls.append(
            contentsOf: replaceRawDomainsWithMarkdownLinks(in: mutableString)
        )
        urls.append(
            contentsOf: replaceRawNIP05IdentifiersWithMarkdownLinks(
                in: mutableString
            )
        )

        replaceOccurrences(of: "^\\s*", with: "", in: mutableString)
        replaceOccurrences(of: "\\s*$", with: "", in: mutableString)
        replaceOccurrences(of: "\\n{3,}", with: "\n\n", in: mutableString)

        return (mutableString as String, urls)
    }

    private func replaceRawDomainsWithMarkdownLinks(
        in mutableString: NSMutableString
    ) -> [URL] {
        // The following pattern uses rules from the Domain Name System page on
        // Wikipedia:
        // https://en.wikipedia.org/wiki/Domain_Name_System#Domain_name_syntax,_internationalization

        // swiftlint:disable:next line_length
        let regexPattern = "(\\s*)(?<url>((https?://){1}|(?<![\\w@.]))([a-zA-Z0-9][-a-zA-Z0-9]{0,62}\\.){1,127}[a-z]{2,63}\\b[-a-zA-Z0-9@:%_\\+.~#?&/=]*)"

        var urls: [URL] = []
        do {
            let string = String(mutableString)
            let regex = try NSRegularExpression(pattern: regexPattern)
            let range = NSRange(location: 0, length: mutableString.length)

            let matches = regex.matches(in: string, range: range).reversed()

            for match in matches {
                let urlRange = Range(match.range(withName: "url"), in: string)
                if let urlRange, let url = URL(string: String(string[urlRange])) {
                    // maintain original order of links by inserting at index 0
                    // (we're looping in reverse)
                    urls.insert(url.addingSchemeIfNeeded(), at: 0)
                    let prettyURL = url.truncatedMarkdownLink
                    regex.replaceMatches(
                        in: mutableString,
                        range: match.range,
                        withTemplate: "$1\(prettyURL)"
                    )
                }
            }
        } catch {
            Log.error("Invalid regex pattern")
        }
        return urls
    }

    private func replaceRawNIP05IdentifiersWithMarkdownLinks(
        in mutableString: NSMutableString
    ) -> [URL] {
        var urls: [URL] = []
        do {
            let string = String(mutableString)

            // The following pattern uses rules from the NIP-05 specification:
            // https://github.com/nostr-protocol/nips/blob/master/05.md
            let regexPattern = "(\\s*)@?(?<nip05>[0-9A-Za-z._-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64})"
            let regex = try NSRegularExpression(
                pattern: regexPattern
            )
            let range = NSRange(location: 0, length: mutableString.length)
            let matches = regex.matches(in: string, range: range).reversed()

            for match in matches {
                let nip05Range = Range(match.range(withName: "nip05"), in: string)
                if let nip05Range {
                    let nip05 = String(string[nip05Range]).lowercased()
                    let url = replaceNIP05IfNeeded(
                        nip05,
                        in: mutableString,
                        range: match.range,
                        regex: regex
                    )
                    if let url {
                        // maintain original order of links by inserting at
                        // index 0 (we're looping in reverse)
                        urls.insert(url, at: 0)
                    }
                }
            }
        } catch {
            Log.error("Invalid regex pattern")
        }
        return urls
    }

    /// Replaces a text found inside a NSMutableString, at a specific range and
    /// found using a specific regex with the provided NIP-05 if it is valid.
    private func replaceNIP05IfNeeded(
        _ nip05: String,
        in mutableString: NSMutableString,
        range: NSRange,
        regex: NSRegularExpression
    ) -> URL? {
        let webLink = "@\(nip05)"
        guard let url = URL(string: webLink) else {
            return nil
        }
        let prettyURL = "[\(nip05)](\(url.absoluteString))"
        regex.replaceMatches(
            in: mutableString,
            range: range,
            withTemplate: "$1\(prettyURL)"
        )
        return url
    }

    private func replaceOccurrences(
        of target: String,
        with replacement: String,
        in mutableString: NSMutableString
    ) {
        mutableString.replaceOccurrences(
            of: target,
            with: replacement,
            options: .regularExpression,
            range: NSRange(location: 0, length: mutableString.length)
        )
    }
}
