import CoreData

/// Provides a mechanism to store and retrieve an `Event` meant to be used to
/// preview a note the user is composing.
protocol PreviewEventRepository {
    /// Creates a preview event object in the database.
    /// - Parameters
    ///   - jsonEvent: JSONEvent object that holds the preview data.
    ///   - context: Managed object context that will hold the Preview event.
    func createPreviewEvent(from jsonEvent: JSONEvent, in context: NSManagedObjectContext) throws -> Event?

    /// Deletes the preview event object from the database.
    /// - Parameters
    ///   - event: Preview event to delete from the database.
    ///   - context: Managed object context that holds the Preview event.
    func deletePreviewEvent(_ event: Event, in context: NSManagedObjectContext) throws
}

/// Uses `CoreData` to store and retrieve an `Event` meant to be used to
/// preview a note the user is composing.
struct DefaultPreviewEventRepository: PreviewEventRepository {
    /// Creates a preview event object in the database.
    /// - Parameters
    ///   - jsonEvent: JSONEvent object that holds the preview data.
    ///   - context: Managed object context that will hold the Preview event.
    func createPreviewEvent(from jsonEvent: JSONEvent, in context: NSManagedObjectContext) throws -> Event? {
        if let oldPreviewEvent = Event.find(by: Event.previewIdentifier, context: context) {
            try deletePreviewEvent(oldPreviewEvent, in: context)
        }
        var updatedJSONEvent = jsonEvent
        updatedJSONEvent.id = Event.previewIdentifier
        let newPreviewEvent = try EventProcessor.parse(
            jsonEvent: updatedJSONEvent,
            from: nil,
            in: context,
            skipVerification: true
        )
        try context.saveIfNeeded()
        return newPreviewEvent
    }

    /// Deletes the preview event object from the database.
    /// - Parameters
    ///   - event: Preview event to delete from the database.
    ///   - context: Managed object context that holds the Preview event.
    func deletePreviewEvent(_ event: Event, in context: NSManagedObjectContext) throws {
        context.delete(event)
        try context.saveIfNeeded()
    }
}
