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
     
    private let underlyingKey: secp256k1.Signing.XonlyKey
    
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
        self.init(bech32Encoded: npub, prefix: Nostr.publicKeyPrefix)
    }

    init?(note: String) {
        self.init(bech32Encoded: note, prefix: Nostr.notePrefix)
    }

    private init?(bech32Encoded: String, prefix: String) {
        do {
            let (humanReadablePart, checksum) = try Bech32.decode(bech32Encoded)
            guard humanReadablePart == prefix else {
                print("error creating PublicKey: invalid human readable part")
                return nil
            }
            guard let converted = try? checksum.base8FromBase5() else {
                return nil
            }

            let underlyingKey = secp256k1.Signing.XonlyKey(dataRepresentation: converted, keyParity: 0)
            self.init(underlyingKey: underlyingKey)
        } catch {
            print("error creating PublicKey \(error.localizedDescription)")
            return nil
        }
    }

    init(underlyingKey: secp256k1.Signing.XonlyKey) {
        self.underlyingKey = underlyingKey
        self.hex = Data(underlyingKey.bytes).hexString
        self.npub = Bech32.encode(Nostr.publicKeyPrefix, baseEightData: Data(underlyingKey.bytes))
    }
    
    func verifySignature(on event: Event) throws -> Bool {
        // Verify that identifier matches contents
        let calculatedIdentifier = try event.calculateIdentifier()
        guard calculatedIdentifier == event.identifier else {
            return false
        }
        
        let signedBytes = try calculatedIdentifier.bytes
        let schnorrSignature = try secp256k1.Schnorr.SchnorrSignature(dataRepresentation: try event.signature!.bytes)
        var rawPubKey = secp256k1_xonly_pubkey()
        let contextPointer = secp256k1.Context.rawRepresentation
        guard secp256k1_xonly_pubkey_parse(contextPointer, &rawPubKey, underlyingKey.bytes).boolValue else {
            throw KeyError.invalidPubKey
        }
        
        let signatureIsValid = secp256k1_schnorrsig_verify(
            contextPointer,
            schnorrSignature.dataRepresentation.bytes,
            signedBytes,
            signedBytes.count,
            &rawPubKey
        ).boolValue
        
        return signatureIsValid
    }
}
