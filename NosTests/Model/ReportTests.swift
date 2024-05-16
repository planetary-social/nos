import XCTest
@testable import Nos

final class ReportTests: XCTestCase {

    func testFindCategory() throws {
        XCTAssertEqual(
            ReportCategory.findCategory(from: "PN"),
            ReportCategoryType.allCategories[7]
        )
        XCTAssertEqual(
            ReportCategory.findCategory(from: "VI-hum"),
            ReportCategoryType.allCategories[9].subCategories![0]
        )
    }
}
