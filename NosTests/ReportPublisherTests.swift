import XCTest
import CoreData

final class ReportPublisherTests: CoreDataTestCase {
    func testCreatePublicReport() throws {
        let aliceKeyPair = KeyFixture.alice
        let bobKeyPair = KeyFixture.bob

        let note = try createTestEvent(in: testContext, keyPair: bobKeyPair)
        let reportTarget = ReportTarget.note(note)
        let publicReport = ReportPublisher().createPublicReport(
            for: reportTarget,
            category: ReportCategory.findCategory(from: "CL")!,
            pubKey: aliceKeyPair.publicKeyHex
        )
        
        XCTAssertEqual(publicReport.kind, EventKind.report.rawValue)
        XCTAssertEqual(publicReport.pubKey, aliceKeyPair.publicKeyHex)
        XCTAssertEqual(publicReport.tags, [
            ["L", "MOD"],
            ["l", "MOD>CL", "MOD"],
            ["e", note.identifier!, "profanity"],
            ["p", bobKeyPair.publicKeyHex]
        ])
    }

    func testCreateReportRequestDM() throws {
        let aliceKeyPair = KeyFixture.alice
        let bobKeyPair = KeyFixture.bob

        let note = try createTestEvent(in: testContext, keyPair: bobKeyPair)
        let reportRequestDM = ReportPublisher().createReportRequestDM(
            note: note,
            category: ReportCategory.findCategory(from: "CL")!,
            keyPair: aliceKeyPair
        )!
        
        XCTAssertEqual(reportRequestDM.kind, EventKind.giftWrap.rawValue)
        XCTAssertNotEqual(reportRequestDM.pubKey, aliceKeyPair.publicKeyHex)
        XCTAssertNotEqual(reportRequestDM.pubKey, bobKeyPair.publicKeyHex)
        XCTAssertEqual(reportRequestDM.tags, [
            ["p", Reportinator.publicKey.hex]
        ])
    }
    
    // MARK: Helpers
    
    private func createTestEvent(
        in context: NSManagedObjectContext,
        keyPair: KeyPair
    ) throws -> Event {
        let event = Event(context: context)
        event.createdAt = Date(timeIntervalSince1970: TimeInterval(1_675_264_762))
        event.content = "Testing nos #[0]"
        event.kind = 1
        
        let author = Author(context: context)
        author.hexadecimalPublicKey = keyPair.publicKeyHex
        event.author = author
        
        try event.sign(withKey: keyPair)
        
        return event
    }
}
