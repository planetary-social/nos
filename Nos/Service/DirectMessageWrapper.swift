import Foundation
import NostrSDK

enum DirectMessageWrapper {
    /// This wraps a Nostr event into an encrypted bundle that is already signed and ready to be published. (See NIP-17)
    static func wrap(
        message: String,
        senderKeyPair: KeyPair,
        receiverPubkey: RawAuthorID
    ) throws -> JSONEvent {
        let directMessageRumor = JSONEvent(
            pubKey: senderKeyPair.publicKeyHex,
            createdAt: Date(),
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
