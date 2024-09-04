import SwiftUI

// https://stackoverflow.com/a/74416073
extension Font {
    
    static func clarity(_ fontWeight: Font.Weight, textStyle: UIFont.TextStyle = .body) -> Font {
        .custom(
            fontWeight.clarityFontName,
            size: UIFont.preferredFont(forTextStyle: textStyle).pointSize
        )
    }

    static func clarityRegular(_ textStyle: UIFont.TextStyle) -> Font {
        .custom(
            Font.Weight.regular.clarityFontName,
            size: UIFont.preferredFont(forTextStyle: textStyle).pointSize
        )
    }
    
    static func clarityBold(baseSize size: CGFloat, relativeTo textStyle: Font.TextStyle) -> Font {
        .custom(
            Font.Weight.bold.clarityFontName,
            size: size,
            relativeTo: textStyle
        )
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
