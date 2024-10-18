import SwiftUI

// https://stackoverflow.com/a/74416073
extension Font {
    
    static func clarity(
        _ fontWeight: Font.Weight,
        textStyle: Font.TextStyle = .body
    ) -> Font {
        .custom(
            fontWeight.clarityFontName,
            size: textStyle.defaultSize,
            relativeTo: textStyle
        )
    }

    static func clarity(
        _ fontWeight: Font.Weight,
        size: CGFloat,
        textStyle: Font.TextStyle
    ) -> Font {
        .custom(
            fontWeight.clarityFontName,
            size: size,
            relativeTo: textStyle
        )
    }

    static func clarityRegular(_ textStyle: Font.TextStyle) -> Font {
        clarity(.regular, textStyle: textStyle)
    }
    
    static func clarityBold(_ textStyle: Font.TextStyle) -> Font {
        clarity(.bold, textStyle: textStyle)
    }
}

extension Font.Weight {
    var clarityFontName: String {
        switch self {
        case .medium:   "ClarityCity-Medium"
        case .semibold: "ClarityCity-SemiBold"
        case .bold:     "ClarityCity-Bold"
        default:        "ClarityCity-Regular"
        }
    }
}

fileprivate extension Font.TextStyle {
    var uiFontTextStyle: UIFont.TextStyle {
        switch self {
        case .largeTitle:       .largeTitle
        case .title:            .title1
        case .title2:           .title2
        case .title3:           .title3
        case .headline:         .headline
        case .subheadline:      .subheadline
        case .body:             .body
        case .callout:          .callout
        case .footnote:         .footnote
        case .caption:          .caption1
        case .caption2:         .caption2
        case .extraLargeTitle:  .extraLargeTitle
        case .extraLargeTitle2: .extraLargeTitle2
        @unknown default:       UIFont.TextStyle.body
        }
    }
    
    var defaultSize: CGFloat {
        UIFont.preferredFont(
            forTextStyle: uiFontTextStyle,
            compatibleWith: UITraitCollection(preferredContentSizeCategory: .large)
        ).pointSize
    }
}
