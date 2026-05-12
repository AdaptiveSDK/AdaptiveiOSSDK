#if os(iOS)
import Foundation
import AdaptiveCore

public final class AdaptiveMessaging {
    nonisolated(unsafe) public static let shared = AdaptiveMessaging()

    // ── Payload keys ──────────────────────────────────────────────────────────
    public static let extraNotificationId = "adaptive_message_id"
    public static let extraActionUrl      = "adaptive_action_url"

    // ── Store-and-forward (pre-login push token) ──────────────────────────────
    public static func initialize() {
        _ = shared
        AdaptiveLogger.log(tag: "Adaptive Messaging", message: "Messaging module initialized")
    }

    private var lastPostedDeviceToken: (userId: String, token: String)? = nil

    private init() {
        AdaptiveCore.shared.addLoginListener { [weak self] user in
            guard self != nil else { return }
            Task {
                if let pending = MessagingPreferences.getPendingToken() {
                    AdaptiveLogger.log(tag: "Adaptive Messaging", message: "Login detected — flushing pending token for user \(user.userId)")
                    await MessagingRepository.updateFCMToken(token: pending, userId: user.userId)
                    MessagingPreferences.clearPendingToken()
                }
            }
        }

        AdaptiveCore.shared.addRegistrationListener { [weak self] user in
            guard let self = self else { return }
            guard let token = AdaptiveCore.shared.getLatestFcmToken() else { return }
            if let last = self.lastPostedDeviceToken, last.userId == user.userId, last.token == token { return }
            Task { [weak self] in
                await MessagingRepository.updateFCMToken(token: token, userId: user.userId)
                self?.lastPostedDeviceToken = (user.userId, token)
            }
        }
    }

    // MARK: - FCM Token

    public func updateFCMToken(token: String) async {
        AdaptiveCore.shared.checkInitialization()
        AdaptiveCore.shared.saveFcmToken(token)
        if let currentUser = AdaptiveCore.shared.currentUser {
            await MessagingRepository.updateFCMToken(token: token, userId: currentUser.userId)
        } else {
            MessagingPreferences.savePendingToken(token)
        }
    }

    // MARK: - Notification Status

    /// Reports a notification lifecycle status event.
    /// Fires immediately — no login required; device_id is always included,
    /// user_id is attached only when a user is currently authenticated.
    public func reportNotificationStatus(
        notificationId: String,
        status: String
    ) {
        Task {
            await MessagingRepository.sendNotificationStatus(
                notificationId: notificationId,
                status: status
            )
        }
    }

    /// Convenience: fires DELIVERED_CONFIRMED immediately on payload receipt.
    public func markNotificationDeliveredConfirmed(notificationId: String) {
        reportNotificationStatus(notificationId: notificationId, status: NotificationStatus.deliveryConfirmed.rawValue)
    }

    // MARK: - Notification Display

    public func isAdaptiveNotification(data: String) -> Bool {
        guard let jsonData = data.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return false
        }
        return String(describing: jsonObject["source"]) == "adaptive"
    }

    /// Parse an Adaptive FCM payload and display the notification locally.
    /// Sends DELIVERED_CONFIRMED immediately, then VIEWED once the banner appears.
    public func showNotification(from payload: String) {
        guard let jsonData = payload.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return
        }

        var title   = "Notification"
        var message = ""

        if let notification = json["notification"] as? [String: Any] {
            title   = notification["title"]       as? String ?? title
            message = notification["description"] as? String ?? message
        } else {
            title   = json["title"]       as? String ?? title
            message = json["description"] as? String ?? json["body"] as? String ?? message
        }

        let notificationId = json[AdaptiveMessaging.extraNotificationId] as? String
        let actionUrl      = json[AdaptiveMessaging.extraActionUrl]       as? String

        guard !message.isEmpty else { return }

        if let nid = notificationId, !nid.isEmpty {
            markNotificationDeliveredConfirmed(notificationId: nid)
            NotificationHandler.shared.showNotification(
                title: title,
                message: message,
                notificationId: nid,
                actionUrl: actionUrl
            )
        } else {
            NotificationHandler.shared.showNotification(title: title, message: message)
        }
    }
}
#endif
