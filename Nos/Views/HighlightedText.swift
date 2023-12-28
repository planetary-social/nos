//
//  HighlightedText.swift
//  Planetary
//
//  Created by Matthew Lorentz on 7/20/22.
//  Copyright © 2022 Verse Communications Inc. All rights reserved.
//

import SwiftUI
import Logger

/// A block of markdown text that optionally highlights one word with a gradient and tappable link.
struct HighlightedText: View {
    
    /// The full text that should be displayed.
    let text: String
    
    /// The word that should be highlighted, if any. Must be a substring of `text`.
    let highlightedWord: String?
    
    /// The gradient that will be used to highlight the word.
    let highlightGradient: LinearGradient
    
    let foregroundColor: Color
    
    let font: Font
    
    /// A link that the highlighted word will open if tapped. Optional.
    let link: URL?
    
    /// A model for the segments of the string. `HightlightedText` is built by appending several `Text` views together,
    /// and each `Segment` will eventually be rendered as `Text`
    private enum Segment {
        case body(String)
        case highlighted(String)
        case space
    }
    
    /// An array of segments of text, along with a bool specifying if they should be highlighted.
    private var segments: [Segment]
    
    /// Creates a `HighlightedText`.
    /// - Parameters:
    ///   - text: The full text that should be displayed.
    ///   - highlightedWord: The word that should be highlighted, if any. Must be a substring of `text`.
    ///   - highlight: The gradient that will be used to highlight the word.
    ///   - link: A link that the highlighted word will open if tapped. Optional.
    init(
        text: LocalizedStringResource,
        highlightedWord: String?,
        highlight: LinearGradient,
        textColor: Color = .primaryTxt,
        font: Font = .clarity,
        link: URL?
    ) {
        self.init(
            String(localized: text),
            highlightedWord: highlightedWord,
            highlight: highlight,
            textColor: textColor,
            font: font,
            link: link
        )
    }
    
    /// Creates a `HighlightedText`.
    /// - Parameters:
    ///   - text: The full text that should be displayed.
    ///   - highlightedWord: The word that should be highlighted, if any. Must be a substring of `text`.
    ///   - highlight: The gradient that will be used to highlight the word.
    ///   - link: A link that the highlighted word will open if tapped. Optional.
    init(
        _ text: String,
        highlightedWord: String?,
        highlight: LinearGradient,
        textColor: Color = .primaryTxt,
        font: Font = .clarity,
        link: URL?
    ) {
        self.text = text
        self.highlightedWord = highlightedWord
        self.highlightGradient = highlight
        self.foregroundColor = textColor
        self.font = font
        self.link = link
        
        // If we have a highlighted word we break it up into segments.
        if let highlightedWord = highlightedWord,
            let rangeOfHighlightedWord = text.ranges(of: highlightedWord).first {
            segments = []
            let beforeHighlightedWord = String(text[..<rangeOfHighlightedWord.lowerBound])
            if !beforeHighlightedWord.isEmpty {
                segments.append(.body(beforeHighlightedWord))
                
                // Add spaces back because markdown parsing strips them
                if beforeHighlightedWord.suffix(1) == " " {
                    segments.append(.space)
                }
            }
            
            segments.append(.highlighted(highlightedWord))
            
            let afterHighlightedWord = String(text[rangeOfHighlightedWord.upperBound...])
            if !afterHighlightedWord.isEmpty {
                
                // Add spaces back because markdown parsing strips them
                if afterHighlightedWord.prefix(1) == " " {
                    segments.append(.space)
                }
                
                if let string = try? String(afterHighlightedWord) {
                    segments.append(.body(string))
                }
            }
        } else {
            // no highlighted word, so we just have one segment.
            segments = [.body(text)]
        }
    }
    
    /// A layer that has the body text colored in, but the highlighted word is clear.
    private var bodyText: Text {
        buildTextFromSegments(
            segments: segments,
            highlightBuilder: { string in
                textView(markdown: string).foregroundColor(.clear)
            },
            bodyBuilder: { string in
                textView(markdown: string).foregroundColor(foregroundColor)
            }
        )
    }
    
    /// A layer that has the body text clear, and the highlighted word colored with `highlightGradient`.
    private var highlightedText: some View {
        buildTextFromSegments(
            segments: segments,
            highlightBuilder: { string in
                textView(markdown: string).foregroundColor(.black)
            },
            bodyBuilder: { string in
                textView(markdown: string).foregroundColor(.clear)
            }
        )
        .foregroundLinearGradient(highlightGradient)
    }
    
    /// A layer that has all text clear, but has a tap target where the highlighted word is, which is used to open
    /// the `link`. This is necessary because the gradient overlay interferes with SwiftUI's tap gesture recognizer,
    /// so we can't just add the link in the `highlightedText` layer.
    private var linkText: some View {
        buildTextFromSegments(
            segments: segments,
            highlightBuilder: { string in
                var view: Text
                if let link = link {
                    let linkMarkdown = "[\(string)](\(link.absoluteURL))"
                    view = textView(markdown: linkMarkdown)
                } else {
                    view = textView(markdown: string).foregroundColor(.clear)
                }
                return view
            },
            bodyBuilder: { string in
                textView(markdown: string).foregroundColor(.clear)
            }
        )
        .tint(.clear)
    }
    
    /// This function iterates through a list of segments and builds a single `Text` view from them.
    /// - Parameters:
    ///   - segments: the list of segments that will be iterated through.
    ///   - highlightBuilder: A function that should build and customize the highlighted `Text`.
    ///   - bodyBuilder: A function that should build and customize the body `Text`.
    /// - Returns: A single `Text` view representing the whole paragraph.
    private func buildTextFromSegments(
        segments: [Segment],
        highlightBuilder: (String) -> Text,
        bodyBuilder: (String) -> Text
    ) -> Text {
        var textView = Text("")
        for segment in segments {
            // swiftlint:disable shorthand_operator
            switch segment {
            case .body(let string):
                textView = textView + bodyBuilder(string)
            case .highlighted(let string):
                textView = textView + highlightBuilder(string)
            case .space:
                textView = textView + Text(" ")
            }
            // swiftlint:enable shorthand_operator
        }
        return textView
    }
    
    /// Convenience function to make a `Text` from raw markdown and fail gracefully.
    private func textView(markdown: String) -> Text {
        var attributedString: AttributedString
        do {
            attributedString = try AttributedString(markdown: markdown)
        } catch {
            Log.optional(error)
            attributedString = AttributedString(markdown)
        }
        return Text(attributedString).font(font)
    }
    
    var body: some View {
        // Note: gradient here is too wide. Need to restrict it to just the word "Discover"
        ZStack {
            bodyText
            highlightedText
            linkText
        }
    }
}

struct HighlightedText_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            HighlightedText(
                "A test string",
                highlightedWord: "string",
                highlight: .diagonalAccent,
                link: URL(string: "https://planetary.social") ?? URL.homeDirectory
            )
            .padding()
        }
        .background(Color.previewBg)
        .previewLayout(.sizeThatFits)
        .preferredColorScheme(.dark)
    }
}
