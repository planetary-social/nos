import Security
import UIKit

/// Don't use this outside CurrentUser
@MainActor class Keychain {
    let keychainPrivateKey = "privateKey"
        
    @discardableResult
    func save(key: String, data: Data) -> OSStatus {
        let query =
		[
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrAccount as String: key,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecValueData as String: data
		] as [String: Any]
        
        SecItemDelete(query as CFDictionary)
        
        return SecItemAdd(query as CFDictionary, nil)
    }
    
	func load(key: String) -> Data? {
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
    
    func delete(key: String) -> OSStatus {
        let query =
        [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrAccount as String: key,
        ] as [String: Any]
        
        return SecItemDelete(query as CFDictionary)
    }
}

class MockKeychain: Keychain {
    
    var keychain = [String: Data]()
    
    override func save(key: String, data: Data) -> OSStatus {
        keychain[key] = data
        return 0
    }
    
    override func load(key: String) -> Data? {
        keychain[key]
    }
    
    override func delete(key: String) -> OSStatus {
        keychain.removeValue(forKey: key)
        return 0
    }
}
