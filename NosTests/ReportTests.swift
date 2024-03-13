import XCTest

final class ReportTests: XCTestCase {

    func testFindCategory() throws {
        XCTAssertEqual(ReportCategory.findCategory(from: "PN"), topLevelCategories[5])
        XCTAssertEqual(ReportCategory.findCategory(from: "VI-hum"), topLevelCategories[7].subCategories![0])
    }
}
