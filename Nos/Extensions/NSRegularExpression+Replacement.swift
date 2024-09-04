import Foundation

extension NSRegularExpression {
    
    /// Helper function to perform replacements using NSRegularExpression.
    /// - Parameters:
    ///   - string: The input string.
    ///   - options: Matching options to use.
    ///   - range: A range in which to perform replacements.
    ///   - transform: A transformation function to perform on the match before replacement.
    /// - Returns: The input string with matches replaced.
    func stringByReplacingMatches(
        in string: String,
        options: NSRegularExpression.MatchingOptions = [],
        range: NSRange,
        transform: (NSTextCheckingResult) -> String
    ) -> String {
        var result = ""
        var lastRangeEnd = string.startIndex
        
        for match in matches(in: string, options: options, range: range) {
            guard let matchRange = Range(match.range, in: string) else { continue }
            result += string[lastRangeEnd..<matchRange.lowerBound]
            result += transform(match)
            lastRangeEnd = matchRange.upperBound
        }
        
        result += string[lastRangeEnd..<string.endIndex]
        return result
    }
}
