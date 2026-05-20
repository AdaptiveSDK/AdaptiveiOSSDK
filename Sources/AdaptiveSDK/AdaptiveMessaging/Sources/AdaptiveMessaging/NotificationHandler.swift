#if os(iOS)
import UserNotifications
import AdaptiveCore

// UNUserNotificationCenterDelegate is set on the handler so the SDK can
// intercept foreground presentation, tap (CLICKED), and dismiss (DISMISSED).
final class NotificationHandler: NSObject, UNUserNotificationCenterDelegate {

    static let shared = NotificationHandler()

    private var categoryRegistered = false
    private let categoryId = "adaptive_channel"

    // ── UNNotification userInfo keys used to thread status data ───────────────
    private let kNotificationId = "adaptive_notification_id"
    private let kJourneyId      = "adaptive_journey_id"
    private let kActionUrl      = "adaptive_action_url"

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    // Register category with .customDismissAction so the system calls
    // didReceive(response:) for the dismiss action too.
    private func registerCategoryIfNeeded() {
        guard !categoryRegistered else { return }
        categoryRegistered = true
        let category = UNNotificationCategory(
            identifier: categoryId,
            actions: [],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    // MARK: - Show

    func showNotification(title: String, message: String) {
        showNotification(title: title, message: message, notificationId: nil, actionUrl: nil)
    }

    func showNotification(
        title: String,
        message: String,
        notificationId: String?,
        actionUrl: String?
    ) {
        registerCategoryIfNeeded()

        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            guard let self = self else { return }
            guard settings.authorizationStatus == .authorized else {
                AdaptiveLogger.log(tag: "NotificationHandler", message: "Notification permission not granted")
                return
            }

            let content = UNMutableNotificationContent()
            content.title = title
            content.body  = message
            content.sound = .default
            content.categoryIdentifier = self.categoryId

            // Stash status-tracking fields in userInfo so delegate callbacks
            // can read them without any external state.
            var info: [String: Any] = [:]
            if let nid = notificationId { info[self.kNotificationId] = nid }
            if let url = actionUrl      { info[self.kActionUrl]       = url }
            content.userInfo = info

            let identifier = notificationId ?? UUID().uuidString
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
            let request  = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    AdaptiveLogger.log(tag: "NotificationHandler", message: "Failed to show notification: \(error)")
                }
            }
        }
    }

    // Foreground display — only show banner for Adaptive-owned notifications.
    // Non-Adaptive notifications (e.g. FCM) are suppressed here so the Flutter
    // layer can handle them via flutter_local_notifications without duplicates.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let info           = notification.request.content.userInfo
        let notificationId = info[kNotificationId] as? String

        // Only present notifications created by Adaptive SDK.
        guard let nid = notificationId, !nid.isEmpty else {
            // Not an Adaptive notification — suppress and let Flutter handle it.
            completionHandler([])
            return
        }

        AdaptiveMessaging.shared.reportNotificationStatus(notificationId: nid, status: NotificationStatus.view.rawValue)
        AdaptiveLogger.log(tag: "NotificationHandler", message: "Notification VIEWED (foreground) id=\(nid)")

        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound])
        } else {
            completionHandler([.alert, .sound])
        }
    }

    // Tap or dismiss.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let info           = response.notification.request.content.userInfo
        let notificationId = info[kNotificationId] as? String
        let actionUrl      = info[kActionUrl]      as? String

        switch response.actionIdentifier {
        case UNNotificationDismissActionIdentifier:
            if let nid = notificationId, !nid.isEmpty {
                AdaptiveMessaging.shared.reportNotificationStatus(notificationId: nid, status: NotificationStatus.dismiss.rawValue)
                AdaptiveLogger.log(tag: "NotificationHandler", message: "Notification DISMISSED id=\(nid)")
            }

        default: // UNNotificationDefaultActionIdentifier == tap
            if let nid = notificationId, !nid.isEmpty {
                    AdaptiveMessaging.shared.reportNotificationStatus(notificationId: nid, status: NotificationStatus.click.rawValue)
                AdaptiveLogger.log(tag: "NotificationHandler", message: "Notification CLICKED id=\(nid)")
            }
            if let urlString = actionUrl, let url = URL(string: urlString) {
                DispatchQueue.main.async { UIApplication.shared.open(url) }
            }
        }

        completionHandler()
    }
}
#endif
