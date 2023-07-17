//
//  String+Markdown.swift
//  Nos
//
//  Created by Matthew Lorentz on 3/9/23.
//

import Foundation
import Logger

extension String {
    /// Find all links in a given string and replaces them with markdown formatted links
    func findAndReplaceUnformattedLinks(in string: String) throws -> String {
        // swiftlint:disable line_length
        let regex = "(?:^|\\s)(?<link>((http|https)?:\\/\\/.)?(www\\.)?[-a-zA-Z0-9@:%._\\+~#=]{2,256}\\.[a-z]{2,6}\\b([-a-zA-Z0-9@:%_\\+.~#?&//=]*))"
        // swiftlint:enable line_length
        let regularExpression = try NSRegularExpression(pattern: regex)
        let wholeRange = NSRange(location: 0, length: string.utf16.count)
        if let match = regularExpression.firstMatch(in: string, range: wholeRange) {
            if let range = Range(match.range(withName: "link"), in: string) {
                let linkDisplayName = "\(string[range])"
                var link = linkDisplayName
                if var url = URL(string: link) {
                    if url.scheme == nil,
                        let httpsURL = URL(string: ("https://\(link)")) {
                        url = httpsURL
                    }
                    link = url.absoluteString
                }
                let replacement = "[\(linkDisplayName)](\(link))"
                return try findAndReplaceUnformattedLinks(in: string.replacingCharacters(in: range, with: replacement))
            }
        }
        return string
    }
    
    static func extractAndRemoveURLs(from string: String) -> (String, [URL]) {
        var urls: [URL] = []
        let mutableString = NSMutableString(string: string)
        let regexPattern = "(\\s*)(https?://[^\\s]*)"
        
        do {
            let regex = try NSRegularExpression(pattern: regexPattern, options: [])
            let range = NSRange(location: 0, length: mutableString.length)
            
            let matches = regex.matches(in: string, options: [], range: range).reversed()
            
            for match in matches {
                if let range = Range(match.range(at: 2), in: string), let url = URL(string: String(string[range])) {
                    urls.append(url)
                    regex.replaceMatches(in: mutableString, options: [], range: match.range, withTemplate: "")
                }
            }
        } catch {
            Log.error("Invalid regex pattern")
        }
        
        return (mutableString as String, urls)
    }

    func findUnformattedLinks() throws -> [URL] {
        // swiftlint:disable line_length
        let regex = "((http|https)?:\\/\\/.)?(www\\.)?[-a-zA-Z0-9@:%._\\+~#=]{2,256}\\.[a-z]{2,6}\\b([-a-zA-Z0-9@:%_\\+.~#?&//=]*)"
        // swiftlint:enable line_length
        
        var links = [URL]()
        let regularExpression = try NSRegularExpression(pattern: regex)
        let wholeRange = NSRange(location: 0, length: self.utf16.count)
        for match in regularExpression.matches(in: self, range: wholeRange) {
            if let range = Range(match.range, in: self),
                let url = URL(string: String(self[range])) {
                links.append(url)
            }
        }
        return links
    }
}
