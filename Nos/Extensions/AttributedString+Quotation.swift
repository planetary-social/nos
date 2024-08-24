import Foundation

extension AttributedString {
    
    /// Wraps this AttributedString with localized quotation marks.
    /// - Parameter locale: The Locale to get the quotation marks from.
    /// - Returns: A new AttributedString, wrapped with localized quotation marks.
    func wrappingWithQuotationMarks(locale: Locale = .current) -> AttributedString {
        var content = self
        
        let beginDelimiter = locale.quotationBeginDelimiter ?? "“"
        let attributesAtBeginning = runs.first?.attributes ?? AttributeContainer()
        content.insert(AttributedString(beginDelimiter, attributes: attributesAtBeginning), at: content.startIndex)
        
        let endDelimiter = locale.quotationEndDelimiter ?? "”"
        let attributesAtEnd = runs.last?.attributes ?? AttributeContainer()
        content.append(AttributedString(endDelimiter, attributes: attributesAtEnd))
        
        return content
    }
}
