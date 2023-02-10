//
//  KeyPair.swift
//  Nos
//
//  Created by Matthew Lorentz on 2/3/23.
//

import Foundation
import secp256k1

struct PublicKey {
    var hex: String
    let npub: String
     
    private let underlyingKey: secp256k1.Signing.XonlyKey
    
    init?(hex: String) {
        do {
            let underlyingKey = try secp256k1.Signing.XonlyKey(rawRepresentation: hex.bytes, keyParity: 0)
            self.init(underlyingKey: underlyingKey)
        } catch {
            print("error creating PublicKey \(error.localizedDescription)")
            return nil
        }
    }
    
    init?(npub: String) {
        do {
            let (humanReadablePart, checksum) = try Bech32.decode(npub)
            guard humanReadablePart == NostrIdentifiers.publicKeyPrefix else {
                print("error creating PublicKey from npub: invalid human readable part")
                return nil
            }
            guard let converted = checksum.base8FromBase5 else {
                return nil
            }
            
            let underlyingKey = secp256k1.Signing.XonlyKey(rawRepresentation: converted, keyParity: 0)
            self.init(underlyingKey: underlyingKey)
        } catch {
            print("error creating PublicKey \(error.localizedDescription)")
            return nil
        }
    }
    
    init(underlyingKey: secp256k1.Signing.XonlyKey) {
        self.underlyingKey = underlyingKey
        self.hex = Data(underlyingKey.bytes).hexString
        self.npub = Bech32.encode(NostrIdentifiers.publicKeyPrefix, baseEightData: Data(underlyingKey.bytes))
    }
}

// https://github.com/nostr-protocol/nips/blob/master/19.md
enum NostrIdentifiers {
    static let privateKeyPrefix = "nsec"
    static let publicKeyPrefix = "npub"
}

struct KeyPair {
    
    var privateKeyHex: String {
        underlyingKey.rawRepresentation.hexString
    }
    
    var publicKeyHex: String {
        publicKey.hex
    }
    
    var nsec: String {
        Bech32.encode(NostrIdentifiers.privateKeyPrefix, baseEightData: underlyingKey.rawRepresentation)
    }
    
    var npub: String {
        publicKey.npub
    }
    
    let publicKey: PublicKey
    private let underlyingKey: secp256k1.Signing.PrivateKey
    
    init?() {
        let key = try! secp256k1.Signing.PrivateKey()
        self.init(privateKeyHex: key.rawRepresentation.hexString)
    }
    
    init?(privateKeyHex: String) {
        
        guard let decoded = privateKeyHex.hexDecoded else {
            return nil
        }
        
        do {
            self.underlyingKey = try .init(rawRepresentation: decoded)
        } catch {
            print("error creating KeyPair \(error.localizedDescription)")
            return nil
        }
        
        publicKey = PublicKey(underlyingKey: underlyingKey.publicKey.xonly)
    }
    
    init?(nsec: String) {
        do {
            let (humanReadablePart, checksum) = try Bech32.decode(nsec)
            guard humanReadablePart == NostrIdentifiers.privateKeyPrefix else {
                print("error creating KeyPair from nsec: invalid human readable part")
                return nil
            }
            
            guard let converted = checksum.base8FromBase5 else {
                return nil
            }
            
            self.underlyingKey = try .init(rawRepresentation: converted)
            publicKey = PublicKey(underlyingKey: underlyingKey.publicKey.xonly)
        } catch {
            print("error creating KeyPair \(error.localizedDescription)")
            return nil
        }
    }
    
    func sign(bytes: inout [UInt8]) throws -> String {
        let privateKeyBytes = try privateKeyHex.bytes
        let privateKey = try secp256k1.Signing.PrivateKey(rawRepresentation: privateKeyBytes)
        
        var randomBytes = [Int8](repeating: 0, count: 64)
        guard
            SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes) == errSecSuccess
        else {
            fatalError("can't copy secure random data")
        }
        
        let rawSignature = try privateKey.schnorr.signature(message: &bytes, auxiliaryRand: &randomBytes)
        return rawSignature.rawRepresentation.hexString
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
        guard let data = try? JSONEncoder().encode(self),
            let result = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return result
    }
}
