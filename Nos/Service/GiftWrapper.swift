import Foundation
import NostrSDK

// TODANIEL: not sure if these function signatures are perfect but they are a sketch of a Swifty interface for gift 
// wrapping
struct GiftWrapper: NIP44v2Encrypting {
    static func wrap(_ rumor: JSONEvent, authorKey: KeyPair, recipient: RawAuthorID) throws -> JSONEvent {
        let seal = try seal(rumor, authorKey: authorKey, recipient: recipient)
        
        // TODO: implement
        let giftWrapped = seal 
        
        return giftWrapped
    }
    
    static func seal(_ rumor: JSONEvent, authorKey: KeyPair, recipient: RawAuthorID) throws -> JSONEvent {
        // TODO: implement
        // let encryptedRumor = encrypt(rumor.string, privateKeyA: authorKey, publicKeyB: recipient)
        let encryptedRumor = "unimplemented"
        var seal = JSONEvent(pubKey: authorKey.publicKeyHex, kind: .seal, tags: [], content: encryptedRumor)
        try seal.sign(withKey: authorKey)
        return seal
    }
}
