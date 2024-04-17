import Foundation
import Dependencies
import Logger
import CoreData

enum Reportinator {
    // swiftlint:disable:next force_unwrapping
    static var publicKey = PublicKey(npub: "npub14h23jzlyvumks4rvrz6ktk36dxfyru8qdf679k7q8uvxv0gm0vnsyqe2sh")!
}

class ReportPublisher {
    @Dependency(\.relayService) private var relayService
    @Dependency(\.currentUser) private var currentUser
    @Dependency(\.analytics) private var analytics
    
    /// Publishes a report for the given target and category.
    func publishPublicReport(for target: ReportTarget, category: ReportCategory, context: NSManagedObjectContext) {
        guard let keyPair = currentUser.keyPair else {
            Log.error("Cannot publish report - No signed in user")
            return 
        }
        
        let event = reportEvent(for: target, category: category, pubKey: keyPair.publicKeyHex)
        
        Task {
            do {
                try await relayService.publishToAll(event: event, signingKey: keyPair, context: context)
                analytics.reported(target)
            } catch {            
                Log.error("Failed to publish report: \(error.localizedDescription)")
            }
        }
    }
    
    func publishPrivateReport(for target: ReportTarget, category: ReportCategory, context: NSManagedObjectContext) {
        guard let keyPair = currentUser.keyPair else {
            Log.error("Cannot publish report - No signed in user")
            return 
        }
        
        let reportRumor = reportEvent(for: target, category: category, pubKey: keyPair.publicKeyHex)
        
        let giftWrappedReport = try! GiftWrapper.wrap(
            reportRumor, 
            authorKey: keyPair, 
            recipient: Reportinator.publicKey.hex
        )
        
        Task {
            do {
                try await relayService.publish(
                    event: giftWrappedReport, 
                    to: Relay.nosAddress, 
                    signingKey: keyPair, 
                    context: context
                )
                analytics.reported(target)
            } catch {            
                Log.error("Failed to publish report: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: Helpers 
    
    private func reportEvent(for target: ReportTarget, category: ReportCategory, pubKey: RawAuthorID) -> JSONEvent {
        var event = JSONEvent(
            pubKey: pubKey, 
            kind: .report, 
            tags: [
                ["L", "MOD"],
                ["l", "MOD>\(category.code)", "MOD"]
            ], 
            content: String(localized: .localizable.reportEventContent(category.displayName))
        )
        
        let nip56Reason = category.nip56Code.rawValue
        event.tags += target.tags(for: nip56Reason)
        
        return event
    }
}    
