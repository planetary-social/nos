import XCTest

final class AttributedString_QuotationsTests: XCTestCase {
    
    func testLocales() {
        let cases = [
            "en": "“test”",
            "fr": "«test»",
            "ja": "「test」",
        ]
        
        for (localeIdentifier, expectedOutput) in cases {
            XCTAssertEqual(
                wrappedTestString(with: localeIdentifier),
                expectedOutput
            )
        }
    }
    
    private func wrappedTestString(with localeIdentifier: String) -> String {
        let content = AttributedString("test")
        let wrapped = content.wrappingWithQuotationMarks(locale: Locale(identifier: localeIdentifier))
        return String(wrapped.characters)
    }
    
    func testExistingAttributesMaintainedForInsertedCharacters() {
        let expectedAttributes = AttributeContainer([.foregroundColor: UIColor.blue])
        let content = AttributedString("test", attributes: expectedAttributes)
        
        let wrapped = content.wrappingWithQuotationMarks(locale: Locale(identifier: "en"))
        XCTAssertEqual(wrapped.runs.first?.attributes, expectedAttributes)
        XCTAssertEqual(wrapped.runs.last?.attributes, expectedAttributes)
    }
}
