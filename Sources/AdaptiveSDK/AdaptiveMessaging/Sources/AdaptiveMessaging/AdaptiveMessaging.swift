#if os(iOS)
import Foundation

public final class AdaptiveMessaging {
    nonisolated(unsafe) public static let shared = AdaptiveMessaging()

    // ── Store-and-forward (pre-login push token) ──────────────────────────────
    //
    // Industry pattern (WebEngage, FreshChat, CleverTap):
    //   1. Push token arrives at any point -- even before the user logs in.
    //   2. We always store the token. If a user is already authenticated we
    //      send it immediately; otherwise we persist it and flush it the
    //      moment login() is called on AdaptiveCore.
    //   3. The device is always identifiable (permanent deviceId). userId is
    //      optional metadata added once the user authenticates.
    //
    // The loginListener is registered once in init and lives for the lifetime
    // of the singleton, so no retain-cycle issues occur.
    // ─────────────────────────────────────────────────────────────────────────

    private init() {
        AdaptiveCore.shared.addLoginListener { [weak self] user in
            guard self != nil else { return }
            Task {
                // 1. Flush pending push token
                if let pending = MessagingPreferences.getPendingToken() {
                    AdaptiveLogger.log(
                        tag: "Adaptive Messaging",
                        message: "Login detected -- flushing pending token for user \(user.userId)"
                    )
                    await MessagingRepository.updateFCMToken(token: pending, userId: user.userId)
                    MessagingPreferences.clearPendingToken()
                    AdaptiveLogger.log(tag: "Adaptive Messaging", message: "Pending token sent successfully")
                }

                // 2. Flush pending events one by one
                let pendingEvents = MessagingPreferences.getPendingEvents()
                if !pendingEvents.isEmpty {
                    AdaptiveLogger.log(
                        tag: "Adaptive Messaging",
                        message: "Login detected -- flushing \(pendingEvents.count) pending event(s) for user \(user.userId)"
                    )
                    MessagingPreferences.clearPendingEvents()
                    for event in pendingEvents {
                        await MessagingRepository.sendEvent(
                            eventName: event.eventName,
                            body: event.body,
                            userId: user.userId
                        )
                    }
                }
            }
        }
    }
            }
        }
    }
    }

    // Register or refresh the push token.
    //
    // Call this from application(_:didRegisterForRemoteNotificationsWithDeviceToken:)
    // or from your FCM Messaging.messaging().token(completion:) callback.
    // It is safe to call at any time -- before or after AdaptiveCore.login().
    //
    // - User already logged in  => token is sent to the server immediately
    //   with the user ID and device ID.
    // - No user yet             => token is persisted locally (survives app
    //   restarts) and is automatically flushed the next time
    //   AdaptiveCore.login() is called, exactly as FreshChat / WebEngage behave.
    public func updateFCMToken(token: String) async {
        AdaptiveCore.shared.checkInitialization()

        if let currentUser = AdaptiveCore.shared.currentUser {
            // Fast path: user is authenticated, send straight away.
            await MessagingRepository.updateFCMToken(token: token, userId: currentUser.userId)
        } else {
            // Deferred path: persist the token and wait for login.
            MessagingPreferences.savePendingToken(token)
            AdaptiveLogger.log(
                tag: "Adaptive Messaging",
                message: "Token stored locally -- will be sent when AdaptiveCore.login() is called"
            )
        }
    }

    /// Send a messaging event to the backend.
    ///
    /// - If the user is already logged in, the event is posted immediately.
    /// - If not, the event is persisted locally and automatically flushed
    ///   (one by one, in order) the next time `AdaptiveCore.login()` is called.
    ///
    /// - Parameters:
    ///   - eventName: Event identifier (used as the API path segment).
    ///   - data:      JSON string representing the event body.
    public func sendEvent(eventName: String, data: String) async {
        AdaptiveCore.shared.checkInitialization()

        if let currentUser = AdaptiveCore.shared.currentUser {
            // Fast path: user is authenticated, send straight away.
            await MessagingRepository.sendEvent(
                eventName: eventName,
                body: data,
                userId: currentUser.userId
            )
        } else {
            // Deferred path: persist the event and wait for login.
            MessagingPreferences.addPendingEvent(PendingEvent(eventName: eventName, body: data))
            AdaptiveLogger.log(
                tag: "Adaptive Messaging",
                message: "Event '\(eventName)' queued -- will be sent when AdaptiveCore.login() is called"
            )
        }
    }

    public func isAdaptiveNotification(data: String) -> Bool {
        guard let jsonData = data.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return false
        }
        return String(describing: jsonObject["source"]) == "adaptive"
    }

    public func showNotification(from payload: String) {
        guard let jsonData = payload.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            showNotitication()
            return
        }
        let title   = json["title"] as? String ?? "Notification"
        let message = json["description"] as? String ?? json["body"] as? String ?? ""
        NotificationHandler.shared.showNotification(title: title, message: message)
    }

    public func showNotitication() {
        NotificationHandler.shared.showNotification(title: "Hello", message: "This is an adaptive message")
    }
}
#endif
