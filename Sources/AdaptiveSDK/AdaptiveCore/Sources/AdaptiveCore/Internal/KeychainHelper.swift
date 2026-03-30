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
            kSecClass            : kSecClassGenericPassword,
            kSecAttrAccount      : key,
            kSecReturnData       : true,
            kSecMatchLimit       : kSecMatchLimitOne
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
}
