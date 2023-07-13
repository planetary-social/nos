//
//  String+Markdown.swift
//  Nos
//
//  Created by Matthew Lorentz on 3/9/23.
//

import Foundation

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
        var processedString = string
        
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: string, options: [], range: NSRange(location: 0, length: string.utf16.count))
        
        for match in matches ?? [] {
            let urlString = (string as NSString).substring(with: match.range)
            if let url = URL(string: urlString) {
                urls.append(url)
                processedString = processedString.replacingOccurrences(of: urlString, with: "")
            }
        }
        
        return (processedString, urls)
    }

    
//    func findAndRemoveLinks(in string: String) throws -> (String, [URL]) {
//        var string = string
//        // swiftlint:disable line_length
//        let regex = "(?:^|\\s)(?<link>((http|https)?:\\/\\/.)?(www\\.)?[-a-zA-Z0-9@:%._\\+~#=]{2,256}\\.[a-z]{2,6}\\b([-a-zA-Z0-9@:%_\\+.~#?&//=]*))"
//        // swiftlint:enable line_length
//        let regularExpression = try NSRegularExpression(pattern: regex)
//        let wholeRange = NSRange(location: 0, length: string.utf16.count)
//        var urls = [URL]()
//        while true {
//            if let match = regularExpression.firstMatch(in: string, range: wholeRange) {
//                if let range = Range(match.range(withName: "link"), in: string) {
//                    let linkDisplayName = "\(string[range])"
//                    var link = linkDisplayName
//                    if var url = URL(string: link) {
//                        if url.scheme == nil,
//                           let httpsURL = URL(string: ("https://\(link)")) {
//                            url = httpsURL
//                        }
//                        urls.append(url)
//                    }
//                    let replacement = "[\(linkDisplayName)](\(link))"
//                    return try findAndRemoveUnformattedLinks(in: string.replacingCharacters(in: range, with: ""))
//                }
//            }
//        }
//        return string
//    }
    
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
