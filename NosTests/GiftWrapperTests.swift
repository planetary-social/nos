import XCTest

final class GiftWrapperTests: XCTestCase {
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
            Date().addingTimeInterval(-TWODAYS)
        )
        XCTAssertLessThan(Date(timeIntervalSince1970: Double(wrappedDM.createdAt)), Date.now)
        XCTAssertNotEqual(wrappedDM.pubKey, senderKeyPair.publicKeyHex)
        XCTAssertNotEqual(wrappedDM.pubKey, receiverKeyPair.publicKeyHex)
        XCTAssertFalse(wrappedDM.content.contains("party"))
    }

    func testGiftUnwrappedDM() throws {
        let senderKeyPair = KeyFixture.alice
        let receiverKeyPair = KeyFixture.bob

        let wrappedDM = try DirectMessageWrapper.wrap(
            message: "Are you going to the party tonight? 🎉",
            senderKeyPair: senderKeyPair,
            receiverPubkey: receiverKeyPair.publicKeyHex
        )

        let unwrappedDM = try GiftWrapper.unwrap(
            giftWrap: wrappedDM,
            receiverKeyPair: receiverKeyPair
        )
        
        XCTAssertEqual(unwrappedDM.kind, EventKind.directMessageRumor.rawValue)
        XCTAssertEqual(unwrappedDM.pubKey, senderKeyPair.publicKeyHex)
        XCTAssertEqual(unwrappedDM.content, "Are you going to the party tonight? 🎉")
    }
}
