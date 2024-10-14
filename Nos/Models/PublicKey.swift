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
        do {
            let identifier = try NostrIdentifier.decode(bech32String: npub)
            guard case let .npub(publicKeyHex) = identifier else {
                return nil
            }
            let underlyingKey = try secp256k1.Signing.XonlyKey(dataRepresentation: publicKeyHex.bytes, keyParity: 0)
            self.init(underlyingKey: underlyingKey)
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
