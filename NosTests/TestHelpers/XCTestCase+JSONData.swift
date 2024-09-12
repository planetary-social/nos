import XCTest

extension XCTestCase {
    func jsonData(filename: String) throws -> Data {
        let url = try XCTUnwrap(Bundle.current.url(forResource: filename, withExtension: "json"))
        return try Data(contentsOf: url)
    }

    func htmlString(filename: String) throws -> String {
        let url = try XCTUnwrap(Bundle.current.url(forResource: filename, withExtension: "html"))
        return try String(contentsOf: url)
    }
}
