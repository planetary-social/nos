import XCTest
import CoreData
import Foundation
import Dependencies
@testable import Nos

/// An `XCTestCase` that sets up an in-memory Core Data stack and resets it between test runs.
class CoreDataTestCase: XCTestCase {
    
    @Dependency(\.persistenceController) var persistenceController
    
    // swiftlint:disable:next implicitly_unwrapped_optional
    var testContext: NSManagedObjectContext!
    
    override func setUp() async throws {
        try await super.setUp()
        persistenceController.resetForTesting()
        testContext = persistenceController.viewContext
    }
}
