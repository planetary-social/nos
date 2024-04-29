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
        
        let publicReport = createPublicReport(for: target, category: category, pubKey: keyPair.publicKeyHex)
        
        Task {
            do {
                try await relayService.publishToAll(event: publicReport, signingKey: keyPair, context: context)
                analytics.reported(target)
            } catch {
                Log.error("Failed to publish report: \(error.localizedDescription)")
            }
        }
    }
    
    func publishPrivateReport(for target: ReportTarget, category: ReportCategory, context: NSManagedObjectContext) {
        switch target {
        case .note(let note):
            guard let keyPair = currentUser.keyPair else {
                Log.error("Cannot publish report - No signed in user")
                return
            }
            
            guard let reportRequestDM = createReportRequestDM(note: note, category: category, keyPair: keyPair) else {
                Log.error("Failed to create gift wrapped report request")
                return
            }
            
            Task {
                do {
                    Log.info("Sending report request to Nos for note \(note.id)")
                    try await relayService.publish(
                        event: reportRequestDM,
                        to: Relay.nosAddress,
                        context: context
                    )
                    analytics.reported(target)
                } catch {
                    Log.error("Failed to publish report: \(error.localizedDescription)")
                }
            }
        case .author:
            Log.error("Private reports for people are no implemented yet")
            return
        }
    }
    
    // MARK: Helpers
    
    struct ReportRequest {
        let reportedEvent: JSONEvent
        let reporterPubkey: RawAuthorID
        let reporterText: String
        
        func toJSON() throws -> String {
            let dictionary: [String: Any] = [
                "reportedEvent": reportedEvent.dictionary,
                "reporterPubkey": reporterPubkey,
                "reporterText": reporterText
            ]
            
            let data = try JSONSerialization.data(withJSONObject: dictionary)
            return String(data: data, encoding: .utf8)!
        }
    }
    
    func createPublicReport(
        for target: ReportTarget,
        category: ReportCategory,
        pubKey: RawAuthorID
    ) -> JSONEvent {
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
    
    func createReportRequestDM(note: Event, category: ReportCategory, keyPair: KeyPair) -> JSONEvent? {
        guard let jsonEvent = note.codable else {
            Log.error("Could not encode note to JSON")
            return nil
        }
        
        do {
            let reportRequestJSON = try ReportRequest(
                reportedEvent: jsonEvent,
                reporterPubkey: keyPair.publicKeyHex,
                reporterText: category.displayName
            ).toJSON()
            
            let reportRequestGiftWrap = try DirectMessageWrapper.wrap(
                message: reportRequestJSON,
                senderKeyPair: keyPair,
                receiverPubkey: Reportinator.publicKey.hex
            )
            return reportRequestGiftWrap
        } catch {
            Log.error("Failed to wrap report request: \(error.localizedDescription)")
            return nil
        }
    }
}
