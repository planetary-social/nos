import Foundation
import Logger

extension String {
    /// Creates a new string with all URLs and any preceding and trailing whitespace removed and removed duplicate
    /// newlines, and returns the new string and an array of all the URLs.
    func extractURLs() -> (String, [URL]) {
        var urls: [URL] = []
        let mutableString = NSMutableString(string: self)

        urls.append(contentsOf: replaceDomains(in: mutableString))
        urls.append(contentsOf: replaceNIP05s(in: mutableString))

        replaceOccurrences(of: "^\\s*", with: "", in: mutableString)
        replaceOccurrences(of: "\\s*$", with: "", in: mutableString)
        replaceOccurrences(of: "\\n{3,}", with: "\n\n", in: mutableString)
        
        return (mutableString as String, urls)
    }

    private func replaceDomains(in mutableString: NSMutableString) -> [URL] {
        // The following pattern uses rules from the Domain Name System page on Wikipedia:
        // https://en.wikipedia.org/wiki/Domain_Name_System#Domain_name_syntax,_internationalization

        // swiftlint:disable:next line_length
        let regexPattern = "(\\s*)(?<url>((https?://){1}|(?<![\\w@]))([a-zA-Z0-9][-a-zA-Z0-9]{0,62}\\.){1,127}[a-z]{2,63}\\b[-a-zA-Z0-9@:%_\\+.~#?&/=]*)"

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

    private func replaceNIP05s(in mutableString: NSMutableString) -> [URL] {
        // The following pattern uses rules from the NIP-05 specification:
        // https://github.com/nostr-protocol/nips/blob/master/05.md

        // swiftlint:disable:next line_length
        let regexPattern = "(\\s*)@?(?<nip05>[0-9a-z._-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64})"

        // [0-9a-z._-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}
        var urls: [URL] = []
        do {
            let string = String(mutableString)
            let regex = try NSRegularExpression(pattern: regexPattern)
            let range = NSRange(location: 0, length: mutableString.length)
            let matches = regex.matches(in: string, range: range).reversed()

            for match in matches {
                let nip05Range = Range(match.range(withName: "nip05"), in: string)
                if let nip05Range {
                    let nip05 = String(string[nip05Range])
                    let webLink = "https://njump.me/\(nip05)"
                    if let url = URL(string: webLink) {
                        // maintain original order of links by inserting at index 0
                        // (we're looping in reverse)
                        urls.insert(url, at: 0)
                        let prettyURL = "[\(nip05)](\(url.absoluteString))"
                        regex.replaceMatches(
                            in: mutableString,
                            range: match.range,
                            withTemplate: "$1\(prettyURL)"
                        )
                    }
                }
            }
        } catch {
            Log.error("Invalid regex pattern")
        }
        return urls
    }

    private func replaceOccurrences(of target: String, with replacement: String, in mutableString: NSMutableString) {
        mutableString.replaceOccurrences(
            of: target,
            with: replacement,
            options: .regularExpression,
            range: NSRange(location: 0, length: mutableString.length)
        )
    }
    
    func findUnformattedLinks() throws -> [URL] {
        // swiftlint:disable line_length
        let regex = "((http|https)?:\\/\\/.)?(www\\.)?[-a-zA-Z0-9@:%._\\+~#=]{2,256}\\.[a-z]{2,6}\\b([-a-zA-Z0-9@:%_\\+.~#?&//=]*)"
        // swiftlint:enable line_length
        
        var links = [URL]()
        let regularExpression = try NSRegularExpression(pattern: regex)
        let wholeRange = NSRange(location: 0, length: self.utf16.count)
        for match in regularExpression.matches(in: self, range: wholeRange) {
            if let range = Range(match.range, in: self), let url = URL(string: String(self[range])) {
                links.append(url)
            }
        }
        return links
    }
}
