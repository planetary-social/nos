//
//  URLExtensionTests.swift
//  NosTests
//
//  Created by Matthew Lorentz on 11/10/23.
//

import XCTest

final class URLExtensionTests: XCTestCase {

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
        XCTAssertEqual(url.truncatedMarkdownLink, "[nostr.com...](www.nostr.com/get-started)")
    }
    
    func testTruncatedMarkdownLink_noScheme_withWWW_noPath_doesNotIncludeEllipsis() {
        let url = URL(string: "www.nos.social")!
        XCTAssertEqual(url.truncatedMarkdownLink, "[nos.social](www.nos.social)")
    }
    
    func testTruncatedMarkdownLink_withShortPath() {
        let url = URL(string: "https://nips.be/1")!
        XCTAssertEqual(url.truncatedMarkdownLink, "[nips.be...](https://nips.be/1)")
    }
}
