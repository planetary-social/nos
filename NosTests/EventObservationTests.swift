//
//  EventObservationTests.swift
//  NosTests
//
//  Created by Matthew Lorentz on 12/8/23.
//

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
final class EventObservationTests: XCTestCase {
    
    private var persistenceController: PersistenceController!
    
    override func invokeTest() {
        withDependencies { dependencies in
            let persistenceController = PersistenceController(containerName: "NosTests", inMemory: true)
            self.persistenceController = persistenceController
            dependencies.persistenceController = persistenceController
        } operation: {
            super.invokeTest()
        }
    }
    
    /// This tests that the same event created in two separate contexts will update correctly in the view when both
    /// contexts are saved. This test exhibits bug https://github.com/planetary-social/nos/issues/697.  
    func testDuplicateEventMergingGivenViewContextSavesFirst() throws {
        // Arrange
        let viewContext = persistenceController.viewContext
        let parseContext = persistenceController.backgroundViewContext
        
        let eventID = "123456"
        let eventContent = "foo bar"
        
        // Act
        let stubbedEvent = try Event.findOrCreateStubBy(id: eventID, context: viewContext)
//        try viewContext.obtainPermanentIDs(for: [stubbedEvent])
        let fullEvent = try Event.findOrCreateStubBy(id: eventID, context: parseContext)
//        try parseContext.obtainPermanentIDs(for: [fullEvent])
        fullEvent.content = eventContent
        
        let view = EventObservationTestView()
        ViewHosting.host(view: view.environment(\.managedObjectContext, persistenceController.container.viewContext))
        let expectNullContent = view.inspection.inspect { view in
            let eventContentInView = try view.find(ViewType.Text.self).string()
            XCTAssertEqual(eventContentInView, "null")
        }
        wait(for: [expectNullContent], timeout: 0.1)
        
//        XCTAssertEqual(stubbedEvent.objectID, fullEvent.objectID)
        
        try parseContext.save()
        try viewContext.save()
        
//        XCTAssertEqual(stubbedEvent.objectID, fullEvent.objectID)
        
        let expectContent = view.inspection.inspect { view in
            let eventContentInView = try view.find(ViewType.Text.self).string()
            XCTAssertEqual(eventContentInView, eventContent)
        }
        wait(for: [expectContent], timeout: 0.1)
    }
    
    /// This tests that the same event created in two separate contexts will update correctly in the view when both
    /// contexts are saved. This test exhibits bug https://github.com/planetary-social/nos/issues/697.  
    func testDuplicateEventMergingGivenParseContextSavesFirst() throws {
        // Arrange
        let viewContext = persistenceController.viewContext
        let parseContext = persistenceController.parseContext
        
        let eventID = "123456"
        let eventContent = "foo bar"
        
        // Act
        let stubbedEvent = try Event.findOrCreateStubBy(id: eventID, context: viewContext)
        try viewContext.obtainPermanentIDs(for: [stubbedEvent])
        let fullEvent = try Event.findOrCreateStubBy(id: eventID, context: parseContext)
        try parseContext.obtainPermanentIDs(for: [fullEvent])
        fullEvent.content = eventContent
        
        let view = EventObservationTestView()
        ViewHosting.host(view: view.environment(\.managedObjectContext, persistenceController.container.viewContext))
        let expectNullContent = view.inspection.inspect { view in
            let eventContentInView = try view.find(ViewType.Text.self).string()
            XCTAssertEqual(eventContentInView, "null")
        }
        wait(for: [expectNullContent], timeout: 0.1)
        
        try parseContext.save()
        try viewContext.save()
        
        let expectContent = view.inspection.inspect { view in
            let eventContentInView = try view.find(ViewType.Text.self).string()
            XCTAssertEqual(eventContentInView, eventContent)
        }
        wait(for: [expectContent], timeout: 0.1)
    }
    
    func _testObjectIDsSavingViewContextFirst() throws {
        // Arrange
        let viewContext = persistenceController.viewContext
        let parseContext = persistenceController.parseContext
        
        let eventID = "123456"
        let eventContent = "foo bar"
        
        // Act
        let stubbedEvent = try Event.findOrCreateStubBy(id: eventID, context: viewContext)
        let viewContextObjectID = stubbedEvent.objectID
        try viewContext.obtainPermanentIDs(for: [stubbedEvent])
        let fullEvent = try Event.findOrCreateStubBy(id: eventID, context: parseContext)
        let fullEventObjectID = fullEvent.objectID
        fullEvent.content = eventContent
        
        try viewContext.save()
        try parseContext.save()
        
        print(fullEventObjectID)
        XCTAssertEqual(fullEvent.objectID, viewContextObjectID) 
        XCTAssertEqual(stubbedEvent.objectID, viewContextObjectID) // why did stubbed event's object ID change but full event did not?
        XCTAssertEqual((try viewContext.existingObject(with: viewContextObjectID) as! Event).content, eventContent)
    }
    
    func _testObjectIDsSavingParseContextFirst() throws {
        // Arrange
        let viewContext = persistenceController.viewContext
        let parseContext = persistenceController.parseContext
        
        let eventID = "123456"
        let eventContent = "foo bar"
        
        // Act
        let stubbedEvent = try Event.findOrCreateStubBy(id: eventID, context: viewContext)
        let viewContextObjectID = stubbedEvent.objectID
        let fullEvent = try Event.findOrCreateStubBy(id: eventID, context: parseContext)
        let fullEventObjectID = fullEvent.objectID
        fullEvent.content = eventContent
        
        try parseContext.save()
        try viewContext.save()
        
        XCTAssertEqual(fullEvent.objectID, viewContextObjectID)
        XCTAssertEqual(stubbedEvent.objectID, viewContextObjectID)
    }
}
