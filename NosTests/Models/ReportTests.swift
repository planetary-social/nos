import XCTest

final class ReportTests: XCTestCase {

    func testFindCategory() throws {
        XCTAssertEqual(
            ReportCategory.findCategory(from: "PN"),
            ReportCategoryType.allCategories[8]
        )
    }
}
