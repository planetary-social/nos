import XCTest

final class ReportTests: XCTestCase {

    func testFindCategory() throws {
        XCTAssertEqual(ReportCategory.findCategory(from: "PN"), allCategories[5])
        XCTAssertEqual(ReportCategory.findCategory(from: "VI-hum"), allCategories[7].subCategories![0])
    }
}
