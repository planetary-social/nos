import CoreData
import Logger

extension NSPersistentContainer {

    /// Deletes all entities in this container.
    ///
    /// - Note: This function assumes that all contexts using the container have their
    ///         `automaticallyMergesChangesFromParent` property set to true.
    func deleteAllEntities() async {
        assert(
            viewContext.automaticallyMergesChangesFromParent,
            "All associated contexts must automatically merge changes from their parent."
        )

        let entityNames = managedObjectModel.entities.compactMap { $0.name }

        let context = newBackgroundContext()
        await context.perform {
            for entityName in entityNames {
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                deleteRequest.resultType = .resultTypeCount

                do {
                    let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
                    Log.info("Deleted \(result?.result ?? 0) of type \(entityName)")
                } catch {
                    print("Failed to batch delete entity: \(entityName), error: \(error)")
                }
            }

            if context.hasChanges {
                try? context.save()
            }
        }
    }
}
