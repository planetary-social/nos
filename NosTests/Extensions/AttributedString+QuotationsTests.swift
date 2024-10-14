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
}
