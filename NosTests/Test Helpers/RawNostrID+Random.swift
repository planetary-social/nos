//
//  RawNostrID+Random.swift
//  NosTests
//
//  Created by Matthew Lorentz on 1/24/24.
//

import Foundation

extension RawNostrID {
    static var random: RawNostrID {
        var randomBytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        
        let hexString = randomBytes.map { String(format: "%02x", $0) }.joined()
        return hexString
    }
}
