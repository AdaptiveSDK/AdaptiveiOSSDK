import Foundation

internal enum KeychainHelper {

    static func save(key: String, data: Data) {
        let query: [CFString: Any] = [
            kSecClass       : kSecClassGenericPassword,
            kSecAttrAccount : key,
            kSecValueData   : data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func read(key: String) -> Data? {
        let query: [CFString: Any] = [
            kSecClass       : kSecClassGenericPassword,
            kSecAttrAccount : key,
            kSecReturnData  : true,
            kSecMatchLimit  : kSecMatchLimitOne
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        return result as? Data
    }

    static func delete(key: String) {
        let query: [CFString: Any] = [
            kSecClass       : kSecClassGenericPassword,
            kSecAttrAccount : key
        ]
        SecItemDelete(query as CFDictionary)
    }

    // Returns the permanent device ID for this app installation.
    // A random UUID is generated on first call and stored in the Keychain
    // permanently -- the device is always identifiable regardless of whether
    // a user is logged in (same approach as WebEngage / CleverTap).
    static func getOrCreateDeviceId() -> String {
        let key = "adaptive_device_id"
        if let data = read(key: key), let id = String(data: data, encoding: .utf8) {
            return id
        }
        let newId = UUID().uuidString
        if let data = newId.data(using: .utf8) {
            save(key: key, data: data)
        }
        return newId
    }
}
