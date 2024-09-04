import XCTest

final class ReportCategoryTests: XCTestCase {

    func testFindCategory() throws {
        XCTAssertEqual(
            ReportCategory.findCategory(from: "PN"),
            ReportCategoryType.allCategories[8]
        )
    }
}
