//
//  Localization+Nos.swift
//  Nos
//
//  Created by Matthew Lorentz on 4/17/23.
//

import Foundation
import SwiftUI
import SwiftUINavigation

extension Localizable {

    // replaces keys in the string with values from the dictionary passed
    // case greeting = "Hello {{ name }}."
    // greeting.text(["name": ]) -> Hello
    func text(_ arguments: [String: String]) -> String {
        do {
            var text = self.string
            for (key, value) in arguments {
                let regex = try NSRegularExpression(pattern: "\\{\\{\\s*\(key)\\s*\\}\\}", options: .caseInsensitive)
                text = regex.stringByReplacingMatches(
                    in: text,
                    options: NSRegularExpression.MatchingOptions(rawValue: 0),
                    range: NSRange(location: 0, length: text.count),
                    withTemplate: value
                )
            }
            return text
        } catch {
            return ""
        }
    }

    /// Use this function in place of `text(_ arguments:[String: String]) -> String` to use Markdown-formatted text
    func localizedMarkdown(_ arguments: [String: String]) -> LocalizedStringKey {
        LocalizedStringKey(text(arguments))
    }

    var uppercased: String {
        string.uppercased()
    }

    var view: Text {
        Text(string)
    }
    
    func view(_ arguments: [String: String]) -> Text {
        Text(text(arguments))
    }
    
    var textState: TextState {
        TextState(string)
    }
}
