//
//  String+Markdown.swift
//  Nos
//
//  Created by Matthew Lorentz on 3/9/23.
//

import Foundation

extension String {
    /// Find all links in a given string and replaces them with markdown formatted links
    func findUnformattedLinks(in markdown: String) throws -> String {
        // swiftlint:disable line_length
        let regex = "(?:^|\\s)(?<link>((http|https)?:\\/\\/.)?(www\\.)?[-a-zA-Z0-9@:%._\\+~#=]{2,256}\\.[a-z]{2,6}\\b([-a-zA-Z0-9@:%_\\+.~#?&//=]*))"
        // swiftlint:enable line_length
        let regularExpression = try NSRegularExpression(pattern: regex)
        let wholeRange = NSRange(location: 0, length: markdown.utf16.count)
        if let match = regularExpression.firstMatch(in: markdown, range: wholeRange) {
            if let range = Range(match.range(withName: "link"), in: markdown) {
                let link = "\(markdown[range])"
                let replacement = "[\(link)](\(link))"
                return try findUnformattedLinks(in: markdown.replacingCharacters(in: range, with: replacement))
            }
        }
        return markdown
    }
}
