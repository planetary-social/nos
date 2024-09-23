import XCTest
import Dependencies
import SwiftUI
import ViewInspector
import Combine
import CoreData
        
// This is a bit of instrumentation recommended by the ViewInspector package to set up views for asynchronous inspection
// see https://github.com/nalexn/ViewInspector/blob/0.9.10/guide.md#approach-2
internal final class Inspection<V> {
    
    let notice = PassthroughSubject<UInt, Never>()
    var callbacks = [UInt: (V) -> Void]()
    
    func visit(_ view: V, _ line: UInt) {
        if let callback = callbacks.removeValue(forKey: line) {
            callback(view)
        }
    }
}

extension Inspection: InspectionEmissary { }

struct EventObservationTestView: View {
    @FetchRequest<Event>(
        entity: Event.entity(), 
        sortDescriptors: [NSSortDescriptor(keyPath: \Event.createdAt, ascending: true)]
    ) var events
        
    internal let inspection = Inspection<Self>() 
    var body: some View {
        List(events) { event in 
            Text(event.content ?? "null")
        }
        .onReceive(inspection.notice) { self.inspection.visit(self, $0) } 
    }
}

/// Testing that our SwiftUI Views can successfully observe Event changes from Core Data
final class EventObservationTests: CoreDataTestCase {
    
    /// This tests that the same event created in two separate contexts will update correctly in the view when both
    /// contexts are saved. This test exhibits bug https://github.com/planetary-social/nos/issues/697.  
    func testDuplicateEventMergingGivenParseContextSavesFirst() throws {
        XCTExpectFailure("This test is failing intermittently, see #703", options: .nonStrict())
        // Arrange
        let viewContext = persistenceController.viewContext
        let parseContext = persistenceController.parseContext
        
        let eventID = "123456"
        let eventContent = "foo bar"
        
        // Act
        _ = try Event.findOrCreateStubBy(id: eventID, context: viewContext)
        let fullEvent = try Event.findOrCreateStubBy(id: eventID, context: parseContext)
        fullEvent.content = eventContent
        
        let view = EventObservationTestView()
        ViewHosting.host(view: view.environment(\.managedObjectContext, persistenceController.viewContext))
        // sanity check
        let expectNullContent = view.inspection.inspect { view in
            let eventContentInView = try view.find(ViewType.Text.self).string()
            XCTAssertEqual(eventContentInView, "null")
        }
        wait(for: [expectNullContent], timeout: 0.1)
        
        // If you reverse the two lines below this test fails. Not sure why :( but I'm not seeing #703 anymore when
        // running the full app. 
        try parseContext.save()
        
        let expectContent = view.inspection.inspect { view in
            let eventContentInView = try view.find(ViewType.Text.self).string()
            XCTAssertEqual(eventContentInView, eventContent)
        }
        wait(for: [expectContent], timeout: 0.1)
    }
}
