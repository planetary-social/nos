//
//  VerifiableEvent.swift
//  Nos
//
//  Created by Daniel on 24/4/24.
//

import secp256k1
import secp256k1_bindings

protocol VerifiableEvent {
    var pubKey: String { get }
    var signature: String? { get }
    var identifier: RawEventID? { get }
    
    func verifySignature(for pubkey: PublicKey) throws -> Bool
    func calculateIdentifier() throws -> String
}

extension VerifiableEvent {
    func verifySignature(for pubkey: PublicKey) throws -> Bool {
        // Verify that identifier matches contents
        let calculatedIdentifier = try self.calculateIdentifier()
        
        guard calculatedIdentifier == self.identifier else {
            return false
        }
        
        let signedBytes = try calculatedIdentifier.bytes
        let schnorrSignature = try secp256k1.Schnorr.SchnorrSignature(dataRepresentation: try self.signature!.bytes)
        var rawPubKey = secp256k1_xonly_pubkey()
        let contextPointer = secp256k1.Context.rawRepresentation
        guard secp256k1_xonly_pubkey_parse(contextPointer, &rawPubKey, pubkey.bytes).boolValue else {
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
    
    func verifySignature(for rawAuthorId: RawAuthorID) throws -> Bool {
        guard let publicKey = PublicKey(hex: rawAuthorId) else {
            return false
        }
        
        return try self.verifySignature(for: publicKey)
    }
    
    func verifySignature() throws -> Bool {
        return try self.verifySignature(for: self.pubKey)
    }
}
