import Foundation
import Logger
import secp256k1

/// A model for Ed25519 public/private key pairs. In Nostr one KeyPair identifies a single author (although one author
/// may have multiple keys). KeyPair includes private key which can be used for signing new events.
struct KeyPair {
    
    var privateKeyHex: String {
        underlyingKey.dataRepresentation.hexString
    }
    
    var publicKeyHex: RawAuthorID {
        publicKey.hex
    }
    
    var nsec: String {
        Bech32.encode(NostrIdentifierPrefix.privateKey, baseEightData: underlyingKey.dataRepresentation)
    }
    
    var npub: String {
        publicKey.npub
    }
    
    let publicKey: PublicKey
    private let underlyingKey: secp256k1.Signing.PrivateKey
    
    init?() {
        do {
            let key = try secp256k1.Signing.PrivateKey()
            self.init(privateKeyHex: key.dataRepresentation.hexString)
        } catch {
            Log.debug("Could not create a secp254k1 key")
            return nil
        }
    }
    
    init?(privateKeyHex: String) {
        
        guard let decoded = privateKeyHex.hexDecoded else {
            return nil
        }
        
        do {
            self.underlyingKey = try .init(dataRepresentation: decoded)
        } catch {
            print("error creating KeyPair \(error.localizedDescription)")
            return nil
        }
        
        publicKey = PublicKey(underlyingKey: underlyingKey.publicKey.xonly)
    }
    
    init?(nsec: String) {
        do {
            let identifier = try NostrIdentifier.decode(bech32String: nsec)
            guard case let .nsec(privateKeyHex) = identifier else {
                print("Error decoding nsec")
                return nil
            }
            self.underlyingKey = try .init(dataRepresentation: privateKeyHex.bytes)
            publicKey = PublicKey(underlyingKey: underlyingKey.publicKey.xonly)
        } catch {
            print("Error creating KeyPair: \(error.localizedDescription)")
            return nil
        }
    }
    
    func sign(bytes: inout [UInt8]) throws -> String {
        let privateKeyBytes = try privateKeyHex.bytes
        let privateKey = try secp256k1.Schnorr.PrivateKey(dataRepresentation: privateKeyBytes)
        
        var randomBytes = [Int8](repeating: 0, count: 64)
        guard
            SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes) == errSecSuccess
        else {
            fatalError("can't copy secure random data")
        }
        
        let rawSignature = try privateKey.signature(message: &bytes, auxiliaryRand: &randomBytes)
        return rawSignature.dataRepresentation.hexString
    }
}

extension KeyPair: Codable {
    enum CodingKeys: CodingKey {
        case privateKeyString
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let privateKeyHex = try container.decode(String.self, forKey: .privateKeyString)
        guard let decodedKeypair = KeyPair(privateKeyHex: privateKeyHex) else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: [CodingKeys.privateKeyString],
                debugDescription: "Could not initialize from hex string"
            ))
        }
        self = decodedKeypair
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(privateKeyHex, forKey: .privateKeyString)
    }
}

extension KeyPair: RawRepresentable {
    
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
            let result = try? JSONDecoder().decode(KeyPair.self, from: data) else {
            return nil
        }
        self = result
    }
    
    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self), let string = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return string
    }
}
