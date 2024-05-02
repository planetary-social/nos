import SwiftUI
import XCTest

final class ContentWarningControllerTests: CoreDataTestCase {
    
    // swiftlint:disable:next implicitly_unwrapped_optional
    var fixture: PreviewData!
    
    override func setUp() async throws {
        try await super.setUp()
        fixture = PreviewData()
        fixture.previewContext = testContext
    }

    func test_noReports() throws {
        // Act
        let sut = ContentWarningController(reports: [], type: .note)
        
        // Assert
        XCTAssertEqual(String(localized: sut.localizedContentWarning), "An error occured.")
    }
    
    func testReason_givenLabel() { 
        // Act
        let sut = ContentWarningController(reports: [fixture.shortNoteReportThree], type: .note)
        
        // Assert
        XCTAssertEqual(
            String(localized: sut.localizedContentWarning), 
            "This note has been reported by **Alice** for spam."
        )
    }
    
    func testReason_givenContent() { 
        // Act
        let sut = ContentWarningController(reports: [fixture.shortNoteReportOne], type: .note)
        
        // Assert
        XCTAssertEqual(
            String(localized: sut.localizedContentWarning), 
            "This note has been reported by **Bob** for impersonation."
        )
    }
    
    func testReason_givenReportType() { 
        // Act
        let sut = ContentWarningController(reports: [fixture.shortNoteReportThree], type: .note)
        
        // Assert
        XCTAssertEqual(
            String(localized: sut.localizedContentWarning), 
            "This note has been reported by **Alice** for spam."
        )
    }
    
    func testWarning_givenNoteReport_oneAuthor_oneReport() { 
        // Act
        let sut = ContentWarningController(reports: [fixture.shortNoteReportOne], type: .note)
        
        // Assert
        XCTAssertEqual(
            String(localized: sut.localizedContentWarning), 
            "This note has been reported by **Bob** for impersonation."
        )
    }
    
    func testWarning_givenOneAuthor_multipleReports() { 
        // Arrange 
        let reports = [fixture.shortNoteReportOne, fixture.reportBobTwo]
        
        // Act
        let sut = ContentWarningController(reports: reports, type: .note)
        
        // Assert
        XCTAssertEqual(
            String(localized: sut.localizedContentWarning), 
            "This note has been reported by **Bob** for harassment, impersonation."
        )
    }
    
    func testWarning_givenNoteReport_multipleAuthors_oneReport() { 
        // Arrange 
        let reports = [fixture.shortNoteReportOne, fixture.shortNoteReportTwo]
        
        // Act
        let sut = ContentWarningController(reports: reports, type: .note)
        
        // Assert
        XCTAssertEqual(
            String(localized: sut.localizedContentWarning), 
            "This note has been reported by **Bob** and **1 other** for harassment, impersonation."
        )
    }
    
    func testWarning_givenAuthorReport_oneAuthor_oneReport() { 
        // Act
        let sut = ContentWarningController(reports: [fixture.shortNoteReportOne], type: .author)
        
        // Assert
        XCTAssertEqual(
            String(localized: sut.localizedContentWarning), 
            "This user has been reported by **Bob** for impersonation."
        ) 
    }
    
    func testWarning_givenAuthorReport_multipleAuthors_oneReport() { 
        // Arrange 
        let reports = [fixture.shortNoteReportOne, fixture.shortNoteReportTwo]
        
        // Act
        let sut = ContentWarningController(reports: reports, type: .author)
        
        // Assert
        XCTAssertEqual(
            String(localized: sut.localizedContentWarning), 
            "This user has been reported by **Bob** and **1 other** for impersonation, other."
        )
    }
}
