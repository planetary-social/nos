import Foundation
import NostrSDK

enum GiftWrapperError: Error {
    case invalidPrivateKey
    case invalidPublicKey
    case serializationError
    case signedRumorError
}

let TWODAYS: TimeInterval = 2 * 24 * 60 * 60
struct NIP44v2Encrypter: NIP44v2Encrypting {}

enum GiftWrapper: NIP44v2Encrypting {
    /// Encrypts and gift-wraps a direct message (See NIP-17, NIP-44 and NIP-59).
    static func wrap(
        rumor: JSONEvent,
        senderKeyPair: KeyPair,
        receiverPubkey: RawAuthorID
    ) throws -> JSONEvent {
        let validatedRumor = try validateRumor(rumor)

        let encryptedRumor = try encryptJSONEvent(
            validatedRumor,
            senderKeyPair: senderKeyPair,
            receiverPubkey: receiverPubkey
        )
        
        let sealCreatedAt = randomTimeUpTo2DaysInThePast()
        var seal = JSONEvent(
            pubKey: senderKeyPair.publicKeyHex,
            createdAt: sealCreatedAt,
            kind: .seal,
            tags: [],
            content: encryptedRumor
        )
        try seal.sign(withKey: senderKeyPair)

        guard let randomKeyPair = KeyPair() else {
            throw GiftWrapperError.invalidPrivateKey
        }

        let encryptedSeal = try encryptJSONEvent(
            seal,
            senderKeyPair: randomKeyPair,
            receiverPubkey: receiverPubkey
        )
        
        let wrapCreatedAt = randomTimeUpTo2DaysInThePast()
        var giftWrap = JSONEvent(
            pubKey: randomKeyPair.publicKeyHex,
            createdAt: wrapCreatedAt,
            kind: .giftWrap,
            tags: [["p", receiverPubkey]],
            content: encryptedSeal
        )
        
        try giftWrap.sign(withKey: randomKeyPair)
        
        // Unsigned, publication will do that
        return giftWrap
    }

    /// Decrypts and verifies a gift-wrapped direct message (See NIP-17, NIP-44 and NIP-59)
    static func unwrap(
        giftWrap: JSONEvent,
        receiverKeyPair: KeyPair
    ) throws -> JSONEvent {
        let encryptedSeal = giftWrap.content
        let seal = try decryptCyphertext(
            encryptedSeal,
            receiverKeyPair: receiverKeyPair,
            senderPubkey: giftWrap.pubKey
        )

        guard let sealEvent = JSONEvent.from(json: seal) else {
            throw GiftWrapperError.serializationError
        }
        
        let encryptedRumor = sealEvent.content

        let rumor = try decryptCyphertext(
            encryptedRumor,
            receiverKeyPair: receiverKeyPair,
            senderPubkey: sealEvent.pubKey
        )
        
        guard let rumorEvent = JSONEvent.from(json: rumor) else {
            throw GiftWrapperError.serializationError
        }
        
        if rumorEvent.pubKey != sealEvent.pubKey {
            throw GiftWrapperError.invalidPublicKey
        }

        return rumorEvent
    }
    
    // MARK: - Helpers
    
    private static func encryptJSONEvent(
        _ jsonEvent: JSONEvent,
        senderKeyPair: KeyPair,
        receiverPubkey: RawAuthorID
    ) throws -> String {
        guard let jsonEventJson = try jsonEvent.toJSON() else {
            throw GiftWrapperError.serializationError
        }
        
        return try encryptPlainText(
            jsonEventJson,
            senderKeyPair: senderKeyPair,
            receiverPubkey: receiverPubkey
        )
    }
    
    private static func encryptPlainText(
        _ plainText: String,
        senderKeyPair: KeyPair,
        receiverPubkey: RawAuthorID
    ) throws -> String {
        let privateKeyA = try toNostrSDKPrivateKey(keyPair: senderKeyPair)
        let publicKeyB = try toNostrSDKPublicKey(rawAuthorId: receiverPubkey)
        
        return try NIP44v2Encrypter().encrypt(
            plaintext: plainText,
            privateKeyA: privateKeyA,
            publicKeyB: publicKeyB
        )
    }
    
    private static func decryptCyphertext(
        _ cyphertext: String,
        receiverKeyPair: KeyPair,
        senderPubkey: RawAuthorID
    ) throws -> String {
        let privateKeyA = try toNostrSDKPrivateKey(keyPair: receiverKeyPair)
        let publicKeyB = try toNostrSDKPublicKey(rawAuthorId: senderPubkey)
        
        return try NIP44v2Encrypter().decrypt(
            payload: cyphertext,
            privateKeyA: privateKeyA,
            publicKeyB: publicKeyB
        )
    }
    
    private static func validateRumor(_ rumor: JSONEvent) throws -> JSONEvent {
        guard rumor.signature.isEmpty else {
            throw GiftWrapperError.signedRumorError
        }

        if rumor.id.isEmpty {
            var mutableRumor = rumor
            mutableRumor.id = try rumor.calculateIdentifier()
            return mutableRumor
        }
        
        return rumor
    }

    private static func toNostrSDKPrivateKey(keyPair: KeyPair) throws -> PrivateKey {
        guard let privateKey = PrivateKey(hex: keyPair.privateKeyHex) else {
            throw GiftWrapperError.invalidPrivateKey
        }

        return privateKey
    }

    private static func toNostrSDKPublicKey(rawAuthorId: RawAuthorID) throws -> NostrSDK.PublicKey {
        guard let publicKey = NostrSDK.PublicKey(hex: rawAuthorId) else {
            throw GiftWrapperError.invalidPublicKey
        }

        return publicKey
    }
    
    static func randomTimeUpTo2DaysInThePast() -> Date {
        Date().addingTimeInterval(-TimeInterval.random(in: 0...TWODAYS))
    }
}
