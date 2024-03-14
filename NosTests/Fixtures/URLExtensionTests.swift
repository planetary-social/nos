import XCTest

final class URLExtensionTests: XCTestCase {

    func test_addingSchemeIfNeeded_adds_scheme_when_there_is_no_scheme() {
        let subject = URL(string: "nos.social")!
        let expected = URL(string: "https://nos.social")!
        let result = subject.addingSchemeIfNeeded()
        XCTAssertEqual(result, expected)
    }

    func test_addingSchemeIfNeeded_adds_scheme_when_url_has_path() {
        let subject = URL(string: "nos.social/about")!
        let expected = URL(string: "https://nos.social/about")!
        let result = subject.addingSchemeIfNeeded()
        XCTAssertEqual(result, expected)
    }

    func test_addingSchemeIfNeeded_adds_scheme_when_url_has_subdomain() {
        let subject = URL(string: "www.nos.social")!
        let expected = URL(string: "https://www.nos.social")!
        let result = subject.addingSchemeIfNeeded()
        XCTAssertEqual(result, expected)
    }

    func test_addingSchemeIfNeeded_does_not_add_scheme_when_http_scheme_already_exists() {
        let subject = URL(string: "http://nos.social")!
        let result = subject.addingSchemeIfNeeded()
        XCTAssertEqual(result, subject)
    }

    func test_addingSchemeIfNeeded_does_not_add_scheme_when_nostr_scheme_already_exists() {
        let subject = URL(string: "nostr:npub1234")!
        let result = subject.addingSchemeIfNeeded()
        XCTAssertEqual(result, subject)
    }

    func testTruncatedMarkdownLink_withEmptyPathExtension() {
        let url = URL(string: "https://subdomain.example.com")!
        XCTAssertEqual(url.truncatedMarkdownLink, "[subdomain.example.com](https://subdomain.example.com)")
    }
    
    func testTruncatedMarkdownLink_withNonEmptyPathExtension() {
        let url = URL(string: "https://example.com/image.png")!
        XCTAssertEqual(url.truncatedMarkdownLink, "[example.com...](https://example.com/image.png)")
    }
    
    func testTruncatedMarkdownLink_withNilHost() {
        let url = URL(string: "nostr:1248904")!
        XCTAssertEqual(url.truncatedMarkdownLink, "[nostr:1248904](nostr:1248904)")
    }
    
    func testTruncatedMarkdownLink_withWWW_removesWWW() {
        let url = URL(string: "https://www.example.com")!
        XCTAssertEqual(url.truncatedMarkdownLink, "[example.com](https://www.example.com)")
    }

    func testTruncatedMarkdownLink_noScheme_withWWW_removesWWW() {
        let url = URL(string: "www.nostr.com/get-started")!
        XCTAssertEqual(url.truncatedMarkdownLink, "[nostr.com...](https://www.nostr.com/get-started)")
    }
    
    func testTruncatedMarkdownLink_noScheme_withWWW_noPath_doesNotIncludeEllipsis() {
        let url = URL(string: "www.nos.social")!
        XCTAssertEqual(url.truncatedMarkdownLink, "[nos.social](https://www.nos.social)")
    }
    
    func testTruncatedMarkdownLink_withShortPath() {
        let url = URL(string: "https://nips.be/1")!
        XCTAssertEqual(url.truncatedMarkdownLink, "[nips.be...](https://nips.be/1)")
    }
}
