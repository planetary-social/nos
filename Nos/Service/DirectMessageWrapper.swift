import Foundation
import NostrSDK

enum DirectMessageWrapper {
    /// Gift-wrapped direct message JSONEvent (See NIP-17)
    static func wrap(
        message: String,
        senderKeyPair: KeyPair,
        receiverPubkey: RawAuthorID
    ) throws -> JSONEvent {
        let directMessageRumor = JSONEvent(
            pubKey: senderKeyPair.publicKeyHex,
            createdAt: GiftWrapper.randomTimeUpTo2DaysInThePast(),
            kind: .directMessageRumor,
            tags: [["p", receiverPubkey]],
            content: message
        )

        return try GiftWrapper.wrap(
            rumor: directMessageRumor,
            senderKeyPair: senderKeyPair,
            receiverPubkey: receiverPubkey
        )
    }
}
