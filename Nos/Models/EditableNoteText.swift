//
//  EditableNoteText.swift
//  Nos
//
//  Created by Matthew Lorentz on 7/26/23.
//

import Foundation
import UIKit

/// A model for the unpublished `contents` field of a Nostr note. This model wraps an `AttributedString` and provides 
/// functions to safely append raw `String` content as well as mentions of nostr entities like other notes or authors.
struct EditableNoteText: Equatable {
    
    /// The underlying string with attributes like font and color.
    private(set) var attributedString: AttributedString
    
    var nsAttributedString: NSAttributedString {
        NSAttributedString(attributedString)
    }
    
    var string: String {
        nsAttributedString.string
    }
    
    private static var font = UIFont.preferredFont(forTextStyle: .body)
    
    lazy var defaultAttributes: AttributeContainer = {
        AttributeContainer(defaultNSAttributes)
    }()
    
    var defaultNSAttributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: UIColor.primaryTxt
    ]
    
    var isEmpty: Bool {
        nsAttributedString.string.isEmpty
    }
    
    // MARK: - Init
    
    init() {
        self.attributedString = AttributedString()
    }
    
    init(string: String) {
        self.attributedString = AttributedString(string)
    }
    
    init(nsAttributedString: NSAttributedString) {
        self.attributedString = AttributedString(nsAttributedString)
    }
    
    // MARK: - Modifying the contents
    
    /// Appends the given string and adds the the default styling attributes.
    mutating func append(_ string: String) {
        attributedString.append(AttributedString(string, attributes: defaultAttributes))
    }
    
    /// Appends the given URL and adds the default styling attributes. Will append a space before the link if needed.
    mutating func append(_ url: URL) {
        if let lastCharacter = string.last, !lastCharacter.isWhitespace {
            append(" ")
        }
        
        attributedString.append(
            AttributedString(
                url.absoluteString,
                attributes: defaultAttributes.merging(
                    AttributeContainer([NSAttributedString.Key.link: url.absoluteString])
                )
            )
        ) 
    }
    
    /// Inserts the mention of an author as a link at the given index of the string. The `index` should be the index 
    /// after a `@` character, which this function will replace.
    mutating func insertMention(of author: Author, at index: AttributedString.Index) {
        guard let url = author.uri else {
            return
        }
        
        let mention = AttributedString(
            "@\(author.safeName)",
            attributes: defaultAttributes.merging(
                AttributeContainer([NSAttributedString.Key.link: url.absoluteString])
            )
        )
        
        attributedString.replaceSubrange((attributedString.index(beforeCharacter: index))..<index, with: mention)
    }

    /// Inserts the mention of an author as a link at the given index of the string. The `index` should be the index
    /// after a `@` character, which this function will replace.
    mutating func insertMention(npub: String, at range: Range<AttributedString.Index>) {
        let mention = AttributedString(
            "@\(npub.prefix(10).appending("..."))",
            attributes: defaultAttributes.merging(
                AttributeContainer([NSAttributedString.Key.link: "nostr:\(npub)"])
            )
        )
        attributedString.replaceSubrange(range, with: mention)
    }

    /// Inserts the mention of an author as a link at the given index of the string. The `index` should be the index
    /// after a `@` character, which this function will replace.
    mutating func insertMention(note: String, at range: Range<AttributedString.Index>) {
        let mention = AttributedString(
            "@\(note.prefix(10).appending("..."))",
            attributes: defaultAttributes.merging(
                AttributeContainer([NSAttributedString.Key.link: "nostr:\(note)"])
            )
        )
        attributedString.replaceSubrange(range, with: mention)
    }
    
    // MARK: - Helpers
    
    func character(before offset: Int) -> Character? {
        let newText = nsAttributedString.string
        if offset > 0 {
            let index = newText.index(newText.startIndex, offsetBy: offset - 1)
            return newText[safe: index] 
        }
        return nil
    }
    
    func difference(from other: EditableNoteText) -> CollectionDifference<String.Element> {
        nsAttributedString.string.difference(from: other.string)
    }
    
    static func == (lhs: EditableNoteText, rhs: EditableNoteText) -> Bool {
        lhs.attributedString == rhs.attributedString
    }
}
