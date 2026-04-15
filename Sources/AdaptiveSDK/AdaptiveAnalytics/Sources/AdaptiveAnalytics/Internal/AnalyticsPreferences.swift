#if os(iOS)
import Foundation
import AdaptiveCore

// Lightweight UserDefaults wrapper that persists analytics events across app
// restarts for the pre-login store-and-forward pattern.
internal enum AnalyticsPreferences {

    private static let suite = UserDefaults(suiteName: "com.adaptive.analytics") ?? .standard
    private static let pendingEventsKey = "pending_analytics_events"
    private static let maxPendingEvents = 50
    static let dedupWindow: TimeInterval = 30 * 60 // 30 minutes

    // ── Pending events (pre-login queue) ─────────────────────────────────────

    /// Append a single event to the persisted queue.
    /// Deduplicates by (queryName + body): if an identical entry already exists it is silently skipped.
    /// Capped at maxPendingEvents; the oldest event is dropped when the limit is reached.
    static func addPendingEvent(_ event: PendingAnalyticsEvent) {
        var events = getPendingEvents()
        // Deduplicate: skip if an identical event (same name + body) is already queued
        let now = Date()
        let isDuplicate = events.contains { e in
            e.queryName == event.queryName &&
            e.body == event.body &&
            now.timeIntervalSince(e.queuedAt) < Self.dedupWindow
        }
        if isDuplicate {
            AdaptiveLogger.log(tag: "Analytics", message: "Event '\(event.queryName)' already queued within dedup window -- skipping")
            return
        }
        if events.count >= maxPendingEvents { events.removeFirst() }
        events.append(event)
        if let data = try? JSONEncoder().encode(events) {
            suite.set(data, forKey: pendingEventsKey)
        }
    }

    /// Retrieve every event that was queued before the user logged in.
    static func getPendingEvents() -> [PendingAnalyticsEvent] {
        guard let data   = suite.data(forKey: pendingEventsKey),
              let events = try? JSONDecoder().decode([PendingAnalyticsEvent].self, from: data)
        else { return [] }
        return events
    }

    /// Clear the persisted queue once all events have been flushed.
    static func clearPendingEvents() {
        suite.removeObject(forKey: pendingEventsKey)
    }
}
#endif
