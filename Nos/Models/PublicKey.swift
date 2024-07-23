import Foundation
import secp256k1
import secp256k1_bindings

enum KeyError: Error {
    case invalidPubKey
    
    var description: String? {
        switch self {
        case .invalidPubKey:
            return "Invalid public key"
        }
    }
}

/// A model for Ed25519 X-only public keys. In Nostr the public key identifies a single author (although one author
/// may have multiple public keys) and is used to cryptographically prove that a given Event was signed by the author.
struct PublicKey {
    var hex: RawAuthorID
    let npub: String
    let bytes: [UInt8]
     
    private let underlyingKey: secp256k1.Signing.XonlyKey

    static func build(npubOrHex: String) -> PublicKey? {
        PublicKey(npub: npubOrHex) ?? PublicKey(hex: npubOrHex)
    }

    init?(hex: String) {
        do {
            let underlyingKey = try secp256k1.Signing.XonlyKey(dataRepresentation: hex.bytes, keyParity: 0)
            self.init(underlyingKey: underlyingKey)
        } catch {
            print("error creating PublicKey \(error.localizedDescription)")
            return nil
        }
    }
    
    init?(npub: String) {
        self.init(bech32Encoded: npub, prefix: NostrIdentifierPrefix.publicKey)
    }

    init?(note: String) {
        self.init(bech32Encoded: note, prefix: NostrIdentifierPrefix.note)
    }

    private init?(bech32Encoded: String, prefix: String) {
        do {
            let identifier = try NostrIdentifier.decode(bech32String: bech32Encoded)
            switch identifier {
            case .npub(let publicKeyHex):
                guard prefix == NostrIdentifierPrefix.publicKey else {
                    return nil
                }
                let underlyingKey = try secp256k1.Signing.XonlyKey(dataRepresentation: publicKeyHex.bytes, keyParity: 0)
                self.init(underlyingKey: underlyingKey)
            case .note(let eventIDHex):
                guard prefix == NostrIdentifierPrefix.note else {
                    return nil
                }
                let underlyingKey = try secp256k1.Signing.XonlyKey(dataRepresentation: eventIDHex.bytes, keyParity: 0)
                self.init(underlyingKey: underlyingKey)
            default:
                return nil
            }
        } catch {
            print("error creating PublicKey \(error.localizedDescription)")
            return nil
        }
    }

    init(underlyingKey: secp256k1.Signing.XonlyKey) {
        self.underlyingKey = underlyingKey
        self.hex = Data(underlyingKey.bytes).hexString
        self.npub = Bech32.encode(NostrIdentifierPrefix.publicKey, baseEightData: Data(underlyingKey.bytes))
        self.bytes = underlyingKey.bytes
    }
}
