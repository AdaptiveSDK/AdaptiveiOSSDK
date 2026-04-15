#if os(iOS)
import Foundation

/// An analytics event that was fired before the user logged in.
///
/// Instances are encoded as JSON and persisted in `UserDefaults` so they
/// survive app restarts. Once `AdaptiveCore.shared.login()` is called, all
/// pending events are flushed to the server one by one, in the order they
/// were queued.
internal struct PendingAnalyticsEvent: Codable {
    let queryName: String
    let body     : String
    let queuedAt : Date

    init(queryName: String, body: String, queuedAt: Date = Date()) {
        self.queryName = queryName
        self.body      = body
        self.queuedAt  = queuedAt
    }
}
#endif
