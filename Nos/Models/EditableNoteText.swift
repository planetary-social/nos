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
    
    lazy var defaultAttributes: AttributeContainer = {
        AttributeContainer(defaultNSAttributes)
    }()
    
    var defaultNSAttributes: [NSAttributedString.Key: Any]

    var isEmpty: Bool {
        nsAttributedString.string.isEmpty
    }
    
    // MARK: - Init
    
    init() {
        self.init(nsAttributedString: NSAttributedString(string: ""))
    }
    
    init(string: String) {
        self.init(nsAttributedString: NSAttributedString(string: string))
    }
    
    init(
        nsAttributedString: NSAttributedString,
        font: UIFont = .preferredFont(forTextStyle: .body),
        foregroundColor: UIColor = .primaryTxt
    ) {
        self.defaultNSAttributes = [
           .font: font,
           .foregroundColor: foregroundColor
        ]
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
        
        var mention = AttributedString(
            "@\(author.safeName)",
            attributes: defaultAttributes.merging(
                AttributeContainer([NSAttributedString.Key.link: url.absoluteString])
            )
        )
        mention.append(AttributedString(
            " ",
            attributes: defaultAttributes
        ))

        attributedString.replaceSubrange((attributedString.index(beforeCharacter: index))..<index, with: mention)
    }

    /// Inserts the mention of an author as a link at the given index of the string. The `index` should be the index
    /// after a `@` character, which this function will replace.
    mutating func insertMention(npub: String, at range: Range<AttributedString.Index>) {
        var mention = AttributedString(
            "@\(npub.prefix(10).appending("..."))",
            attributes: defaultAttributes.merging(
                AttributeContainer([NSAttributedString.Key.link: "nostr:\(npub)"])
            )
        )
        mention.append(AttributedString(stringLiteral: " "))
        var rangeToReplace = range
        if range.lowerBound > attributedString.startIndex {
            let offsetedBound = attributedString.index(range.lowerBound, offsetByCharacters: -1)
            if let char = attributedString[offsetedBound ..< range.lowerBound].characters.first, char == "@" {
                rangeToReplace = offsetedBound ..< range.upperBound
            }
        }
        attributedString.replaceSubrange(rangeToReplace, with: mention)
    }

    /// Inserts the mention of an author as a link at the given index of the string. The `index` should be the index
    /// after a `@` character, which this function will replace.
    mutating func insertMention(note: String, at range: Range<AttributedString.Index>) {
        var mention = AttributedString(
            "@\(note.prefix(10).appending("..."))",
            attributes: defaultAttributes.merging(
                AttributeContainer([NSAttributedString.Key.link: "nostr:\(note)"])
            )
        )
        mention.append(AttributedString(stringLiteral: " "))

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
