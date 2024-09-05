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

    func test_isGIF_returns_false_for_jpg() throws {
        let jpgURL = try XCTUnwrap(URL(string: "https://example.com/one.jpg"))
        XCTAssertFalse(jpgURL.isGIF)
    }

    func test_isGIF_returns_true_for_gif() throws {
        let gifURL = try XCTUnwrap(URL(string: "https://example.com/two.gif"))
        XCTAssertTrue(gifURL.isGIF)
    }

    func test_isGIF_returns_true_for_GIF() throws {
        let capitalizedGIFURL = try XCTUnwrap(URL(string: "https://example.com/three.GIF"))
        XCTAssertTrue(capitalizedGIFURL.isGIF)
    }

    func test_isImage_returns_false_for_mp4() throws {
        let url = try XCTUnwrap(URL(string: "http://example.com/test.mp4"))
        XCTAssertFalse(url.isImage)
    }

    func test_isImage_returns_true_for_image_extensions() throws {
        let pngURL = try XCTUnwrap(URL(string: "http://example.com/test.png"))
        XCTAssertTrue(pngURL.isImage)

        let jpegURL = try XCTUnwrap(URL(string: "http://example.com/test.jpeg"))
        XCTAssertTrue(jpegURL.isImage)

        let jpgURL = try XCTUnwrap(URL(string: "http://example.com/test.jpg"))
        XCTAssertTrue(jpgURL.isImage)

        let gifURL = try XCTUnwrap(URL(string: "http://example.com/test.gif"))
        XCTAssertTrue(gifURL.isImage)
    }

    func test_isImage_returns_true_for_capitalized_path_extension() throws {
        let url = try XCTUnwrap(URL(string: "http://example.com/one.PNG"))
        XCTAssertTrue(url.isImage)
    }

    func test_strippingTrailingSlash_when_no_trailing_slash() throws {
        let url = try XCTUnwrap(URL(string: "wss://relay.nos.social"))
        XCTAssertEqual(url.strippingTrailingSlash(), "wss://relay.nos.social")
    }

    func test_strippingTrailingSlash_strips_trailing_slash() throws {
        let url = try XCTUnwrap(URL(string: "wss://relay.nos.social/"))
        XCTAssertEqual(url.strippingTrailingSlash(), "wss://relay.nos.social")
    }

    func test_truncatedMarkdownLink_withEmptyPathExtension() {
        let url = URL(string: "https://subdomain.example.com")!
        XCTAssertEqual(url.truncatedMarkdownLink, "[subdomain.example.com](https://subdomain.example.com)")
    }
    
    func test_truncatedMarkdownLink_withNonEmptyPathExtension() {
        let url = URL(string: "https://example.com/image.png")!
        XCTAssertEqual(url.truncatedMarkdownLink, "[example.com...](https://example.com/image.png)")
    }
    
    func test_truncatedMarkdownLink_withNilHost() {
        let url = URL(string: "nostr:1248904")!
        XCTAssertEqual(url.truncatedMarkdownLink, "[nostr:1248904](nostr:1248904)")
    }
    
    func test_truncatedMarkdownLink_withWWW_removesWWW() {
        let url = URL(string: "https://www.example.com")!
        XCTAssertEqual(url.truncatedMarkdownLink, "[example.com](https://www.example.com)")
    }

    func test_truncatedMarkdownLink_noScheme_withWWW_removesWWW() {
        let url = URL(string: "www.nostr.com/get-started")!
        XCTAssertEqual(url.truncatedMarkdownLink, "[nostr.com...](https://www.nostr.com/get-started)")
    }
    
    func test_truncatedMarkdownLink_noScheme_withWWW_noPath_doesNotIncludeEllipsis() {
        let url = URL(string: "https://www.nos.social/about")!
        XCTAssertEqual(url.truncatedMarkdownLink, "[nos.social...](https://www.nos.social/about)")
    }
    
    func test_truncatedMarkdownLink_withShortPath() {
        let url = URL(string: "https://nips.be/1")!
        XCTAssertEqual(url.truncatedMarkdownLink, "[nips.be...](https://nips.be/1)")
    }
}
