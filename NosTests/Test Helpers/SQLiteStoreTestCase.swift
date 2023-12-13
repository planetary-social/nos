//
//  SQLiteStoreTestCase.swift
//  NosTests
//
//  Created by Matthew Lorentz on 12/13/23.
//

import XCTest
import CoreData
import Dependencies

// swiftlint:disable implicitly_unwrapped_optional

/// A test case that uses a full core data stack including a SQLite backing store.
class SQLiteStoreTestCase: XCTestCase {
        
    var persistenceController: PersistenceController!
    
    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(containerName: "NosTests", inMemory: true, erase: true)
    }
    
    override func tearDown() {
        persistenceController.tearDown()
        persistenceController = nil
        super.tearDown()
    }
}

// swiftlint:enable implicitly_unwrapped_optional
