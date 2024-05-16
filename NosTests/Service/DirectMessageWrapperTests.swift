import XCTest
@testable import Nos

final class DirectMessageWrapperTests: XCTestCase {
    func testDirectMessageWrapper() throws {
        let senderKeyPair = KeyFixture.alice
        let receiverKeyPair = KeyFixture.bob
        
        let wrappedDM = try DirectMessageWrapper.wrap(
            message: "Are you going to the party tonight? 🎉",
            senderKeyPair: senderKeyPair,
            receiverPubkey: receiverKeyPair.publicKeyHex
        )
        
        XCTAssertEqual(wrappedDM.kind, EventKind.giftWrap.rawValue)
        XCTAssertEqual(wrappedDM.tags, [["p", receiverKeyPair.publicKeyHex]])
        XCTAssertGreaterThan(
            Date(timeIntervalSince1970: Double(wrappedDM.createdAt)),
            Date().addingTimeInterval(-twoDays)
        )
        XCTAssertLessThan(Date(timeIntervalSince1970: Double(wrappedDM.createdAt)), Date.now)
        XCTAssertNotEqual(wrappedDM.pubKey, senderKeyPair.publicKeyHex)
        XCTAssertNotEqual(wrappedDM.pubKey, receiverKeyPair.publicKeyHex)
        XCTAssertFalse(wrappedDM.content.contains("party"))
    }
}
