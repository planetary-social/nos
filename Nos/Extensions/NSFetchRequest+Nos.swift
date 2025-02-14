import CoreData

/// Whether or not two fetch requests are equivalent.
/// - Parameters:
///   - request1: The first request to compare.
///   - request2: The second request to compare.
/// - Returns: True if the two requests are equivalent.
///
/// Note: This is a more accurate check of equality than == for fetch requests.
/// Note: This could not be in an extension on NSFetchRequest due to an Objective-C limitation.
func areFetchRequestsEquivalent<T>(
    _ request1: NSFetchRequest<T>,
    _ request2: NSFetchRequest<T>
) -> Bool {
    request1.predicate == request2.predicate &&
    request1.sortDescriptors == request2.sortDescriptors &&
    request1.fetchLimit == request2.fetchLimit &&
    request1.fetchOffset == request2.fetchOffset &&
    request1.entityName == request2.entityName
}
