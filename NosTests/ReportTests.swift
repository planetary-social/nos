import XCTest

final class ReportTests: XCTestCase {

    func testFindCategory() throws {
        XCTAssertEqual(ReportCategory.findCategory(from: "PN"), categories[5])
        XCTAssertEqual(ReportCategory.findCategory(from: "VI-hum"), categories[7].subCategories![0])
    }
}
