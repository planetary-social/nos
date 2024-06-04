import Dependencies
import ViewInspector
import XCTest

final class CompactNoteViewTests: CoreDataTestCase {
    @MainActor func testNewMediaDisplayDisabledUsesLinkPreviewCarousel() throws {
        // Arrange
        let viewContext = persistenceController.viewContext
        let parseContext = persistenceController.parseContext

        let eventID = "123456"
        let eventContent = "https://nos.social"

        // Act
        _ = try Event.findOrCreateStubBy(id: eventID, context: viewContext)
        let fullEvent = try Event.findOrCreateStubBy(id: eventID, context: parseContext)
        fullEvent.content = eventContent
        fullEvent.kind = 1
        fullEvent.contentLinks = [try XCTUnwrap(URL(string: eventContent))]

        let subject = CompactNoteView(note: fullEvent)
        ViewHosting.host(view: subject.environment(\.managedObjectContext, persistenceController.container.viewContext))
        ViewHosting.host(view: subject.environmentObject(DependencyValues().router))

        // Assert
        let result = try subject.inspect().find(LinkPreviewCarousel.self)
        XCTAssertNotNil(result)
    }
}
