//
//  KeyChain.swift
//  Nos
//
//  Created by Christopher Jorgensen on 2/13/23.
//
// Source: https://stackoverflow.com/questions/37539997/save-and-load-from-keychain-swift
//

import Security
import UIKit

enum KeyChain {
    static let keychainPrivateKey = "privateKey"
        
    @discardableResult
    static func save(key: String, data: Data) -> OSStatus {
        let query =
		[
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
		] as [String: Any]
        
        SecItemDelete(query as CFDictionary)
        
        return SecItemAdd(query as CFDictionary, nil)
    }
    
	static func load(key: String) -> Data? {
        let query =
		[
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
		] as [String: Any]
        
        var dataTypeRef: AnyObject?
        
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == noErr {
            return dataTypeRef as! Data?
        } else {
            return nil
        }
    }
    
    static func delete(key: String) -> OSStatus {
        let query =
        [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrAccount as String: key,
        ] as [String: Any]
        
        return SecItemDelete(query as CFDictionary)
    }
}
