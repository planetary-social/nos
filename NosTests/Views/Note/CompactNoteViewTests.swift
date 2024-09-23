import Dependencies
import ViewInspector
import XCTest

final class CompactNoteViewTests: CoreDataTestCase {
    @MainActor func testNewMediaDisplayDisabledUsesLinkPreviewCarousel() throws {
        // This test passes when run in isolation but it causes other random tests to fail on CI or if you run the 
        // full test suite locally repeatedly (like 100 times). It seems like the link preview carousel is spinning up 
        // some kind of webkit process that sticks around after the test is over and eventually crashes. I tried a few
        // different ways of fixing it but none of them worked. Since it's a relatively simple test and it's for a 
        // feature flag that is only temporary we are going to leave it disabled for now.
        
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
        ViewHosting.host(view: subject.environmentObject(DependencyValues().router))

        // Assert
        let result = try subject.inspect().find(LinkPreviewCarousel.self)
        XCTAssertNotNil(result)
    }
}
