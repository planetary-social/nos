import Foundation

extension AttributedString {

    /// Wraps this AttributedString with localized quotation marks.
    /// - Parameter locale: The Locale to get the quotation marks from.
    /// - Returns: A new AttributedString, wrapped with localized quotation marks.
    func wrappingWithQuotationMarks(locale: Locale = .current) -> AttributedString {
        var content = self

        let beginDelimiter = locale.quotationBeginDelimiter ?? "“"
        content.insert(AttributedString(beginDelimiter), at: content.startIndex)

        let endDelimiter = locale.quotationEndDelimiter ?? "”"
        content.append(AttributedString(endDelimiter))

        return content
    }
}
