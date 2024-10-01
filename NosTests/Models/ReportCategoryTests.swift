import XCTest

final class ReportCategoryTests: XCTestCase {

    func testFindCategory() throws {
        XCTAssertEqual(
            ReportCategory.findCategory(from: "PN"),
            ReportCategory.allCategories[8]
        )
    }
}
