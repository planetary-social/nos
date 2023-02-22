//
//  Profile.swift
//  Nos
//
//  Created by Christopher Jorgensen on 2/21/23.
//

import Foundation

enum Profile {
    /// Step 1: Get public key
    static var publicKey: String? {
        if let privateKeyData = KeyChain.load(key: KeyChain.keychainPrivateKey) {
            let hexString = String(decoding: privateKeyData, as: UTF8.self)
            if let keyPair = KeyPair.init(privateKeyHex: hexString) {
                print("Profile public hex: \(keyPair.publicKey.hex).")
                return keyPair.publicKey.hex
            }
        }
        return nil
    }
    
    /// Step 2: Set relay service and get profile data
    static var relayService: RelayService? {
        didSet {
            if let key = Profile.publicKey {
                let filter = Filter(publicKeys: [key], kinds: [.contactList, .metaData], limit: 2)
                Profile.relayService?.requestEventsFromAll(filter: filter)
            } else {
                print("Error: no public key set for profile")
            }
        }
    }
    
    /// Step 3: Set follows
    static var follows: [Follow]? {
        didSet {
            print("Profile has \(follows?.count ?? 0) follows. Requesting texts.")
            
            let authors = follows?.map { $0.identifier! } ?? []
            let filter = Filter(publicKeys: authors, kinds: [.text], limit: 100)
            Profile.relayService?.requestEventsFromAll(filter: filter)
        }
    }
}
