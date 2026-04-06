#if os(iOS)
import Foundation

// Lightweight UserDefaults wrapper that persists the push token across app
// restarts for the pre-login store-and-forward pattern.
//
// Why UserDefaults (not Keychain)?
// Push tokens are not long-lived secrets -- they rotate frequently and are
// sent over TLS. UserDefaults keeps the implementation simple and avoids a
// Keychain dependency for a transient value.
internal enum MessagingPreferences {

    private static let suite = UserDefaults(suiteName: "com.adaptive.messaging") ?? .standard
    private static let pendingTokenKey = "pending_push_token"

    // Persist a push token that arrived before the user logged in.
    static func savePendingToken(_ token: String) {
        suite.set(token, forKey: pendingTokenKey)
    }

    // Retrieve a previously stored pre-login token, or nil if none exists.
    static func getPendingToken() -> String? {
        suite.string(forKey: pendingTokenKey)
    }

    // Clear the pending token once it has been successfully sent to the server.
    static func clearPendingToken() {
        suite.removeObject(forKey: pendingTokenKey)
    }
}
#endif
