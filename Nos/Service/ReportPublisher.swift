import Foundation
import Dependencies
import Logger
import CoreData

enum Tagr {
    // swiftlint:disable:next force_unwrapping
    static var publicKey = PublicKey(npub: "npub12m2t8433p7kmw22t0uzp426xn30lezv3kxcmxvvcrwt2y3hk4ejsvre68j")!
}

enum ReportError: Error {
    case encodingFailed(String)
    case missingPublicKey(String)
}

final class ReportPublisher {
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
        guard let keyPair = currentUser.keyPair else {
            Log.error("Cannot publish report - No signed in user")
            return
        }
        
        guard let reportRequestDM = createReportRequestDM(target: target, category: category, keyPair: keyPair) else {
            Log.error("Failed to create gift wrapped report request")
            return
        }
        
        Task {
            do {
                switch target {
                case .note(let note):
                    Log.info("Sending report request to Nos for note \(note.id)")
                case .author(let author):
                    guard let npub = author.npubString else {
                        Log.error("Cannot publish report - Missing public key")
                        return
                    }
                    Log.info("Sending report request to Nos for npub \(npub)")
                }
                
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
    }
    
    // MARK: Helpers
    
    func createPublicReport(
        for target: ReportTarget,
        category: ReportCategory,
        pubKey: RawAuthorID
    ) -> JSONEvent {
        var event = JSONEvent(
            pubKey: pubKey,
            kind: .report,
            tags: [],
            content: String.localizedStringWithFormat(String(localized: "reportEventContent"), category.displayName)
        )
        
        let nip56Reason = category.nip56Code.rawValue
        event.tags += target.tags(for: nip56Reason)
        
        return event
    }
    
    func createReportRequestDM(
        target: ReportTarget,
        category: ReportCategory,
        keyPair: KeyPair
    ) -> JSONEvent? {
        do {
            let reportRequestJSON = try ReportRequest(
                reportedTarget: target,
                reporterPubkey: keyPair.publicKeyHex,
                reporterText: category.displayName
            ).toJSON()
            
            let reportRequestGiftWrap = try DirectMessageWrapper.wrap(
                message: reportRequestJSON,
                senderKeyPair: keyPair,
                receiverPubkey: Tagr.publicKey.hex
            )
            return reportRequestGiftWrap
        } catch {
            Log.error("Failed to wrap report request: \(error.localizedDescription)")
            return nil
        }
    }
}

struct ReportRequest {
    let reportedTarget: ReportTarget
    let reporterPubkey: RawAuthorID
    let reporterText: String
    
    func toJSON() throws -> String {
        var dictionary: [String: Any] = [
            "reporterPubkey": reporterPubkey,
            "reporterText": reporterText
        ]
        
        switch reportedTarget {
        case .note(let note):
            guard let jsonEvent = note.codable else {
                throw ReportError.encodingFailed("Could not encode note to JSON")
            }
            
            dictionary[ "reportedEvent"] = jsonEvent.dictionary
        case .author(let author):
            guard let pubKey = author.hexadecimalPublicKey else {
                throw ReportError.missingPublicKey("Author's public key is missing")
            }
            
            dictionary["reportedPubkey"] = pubKey
        }
        
        let data = try JSONSerialization.data(withJSONObject: dictionary)
        return String(decoding: data, as: UTF8.self)
    }
}
