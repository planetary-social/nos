//
//  KeyPair.swift
//  Nos
//
//  Created by Matthew Lorentz on 2/3/23.
//

import Foundation
import secp256k1

struct KeyPair {
    
    var privateKeyString: String
    
    var isValid: Bool {
        do {
            let privateKeyBytes = try privateKeyString.bytes
            let privateKey = try secp256k1.Signing.PrivateKey(rawRepresentation: privateKeyBytes)
            return true
        } catch {
            return false
        }
    }
    
    func sign(bytes: inout [UInt8]) throws -> String {
        let privateKeyBytes = try privateKeyString.bytes
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
        self.privateKeyString = try container.decode(String.self, forKey: .privateKeyString)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(privateKeyString, forKey: .privateKeyString)
    }
}

extension KeyPair: RawRepresentable {
    
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode(KeyPair.self, from: data)
        else {
            return nil
        }
        self = result
    }
    
    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "{}"
        }
        return result
    }
}
