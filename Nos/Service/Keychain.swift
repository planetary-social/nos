import Security
import UIKit

@MainActor protocol Keychain {
    
    var keychainPrivateKey: String { get }
    
    func save(key: String, data: Data) -> OSStatus 
    func load(key: String) -> Data? 
    func delete(key: String) -> OSStatus 
}

/// Don't use this outside CurrentUser
final class SystemKeychain: Keychain {
    
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
            return dataTypeRef as? Data
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

final class InMemoryKeychain: Keychain {
    
    let keychainPrivateKey = "privateKey"
    
    private var keychain = [String: Data]()
    
    func save(key: String, data: Data) -> OSStatus {
        keychain[key] = data
        return 0
    }
    
    func load(key: String) -> Data? {
        keychain[key]
    }
    
    func delete(key: String) -> OSStatus {
        keychain.removeValue(forKey: key)
        return 0
    }
}
