#if os(iOS)
import Foundation

/// A messaging event that was fired before the user logged in.
///
/// Instances are encoded as JSON and persisted in `UserDefaults` so they
/// survive app restarts. Once `AdaptiveCore.login()` is called, all pending
/// events are flushed to the server one by one, in the order they were queued.
internal struct PendingEvent: Codable {
    let eventName: String
    let body: String
}
#endif
