//
//  NProfile.swift
//  Nos
//
//  Created by Martin Dutra on 27/4/23.
//

import Foundation
import secp256k1

/// A struct that abstracts the information included ina nprofile string.
///
/// See https://github.com/nostr-protocol/nips/blob/master/19.md
/// In the future we can parse and include the relays in this struct, but now we just need the public key.
struct NProfile {

    var publicKey: PublicKey

    var publicKeyHex: String {
        publicKey.hex
    }

    init?(nprofile: String) {
        do {
            let (humanReadablePart, checksum) = try Bech32.decode(nprofile)
            guard humanReadablePart == Nostr.profilePrefix else {
                print("error creating Profile from nprofile: invalid human readable part")
                return nil
            }
            guard let converted = checksum.base8FromBase5 else {
                return nil
            }
            var offset = 0
            while offset + 1 < converted.count {
                let type = converted[offset]
                let length = Int(converted[offset + 1])
                if type == 0 {
                    let value = converted.subdata(in: offset + 2 ..< offset + 2 + length)
                    let underlyingKey = secp256k1.Signing.XonlyKey(rawRepresentation: value, keyParity: 0)
                    self.publicKey = PublicKey(underlyingKey: underlyingKey)
                    return
                }
                offset += length + 2
            }
            return nil
        } catch {
            print("error creating Profile \(error.localizedDescription)")
            return nil
        }
    }
}
