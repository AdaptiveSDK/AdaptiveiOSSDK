#if os(iOS)
import Foundation
import AdaptiveCore

internal class MessagingRepository {

    static func updateFCMToken(token: String, userId: String?) async {
        let deviceId = AdaptiveCore.shared.deviceId
        do {
            let payload: [String: Any] = [
                "userId": userId as Any,
                "deviceId": deviceId,
                "token": token
            ]
            let body = try JSONSerialization.data(withJSONObject: payload)
            let bodyString = String(data: body, encoding: .utf8) ?? "{}"
            let result = await AdaptiveCore.shared.post(path: "device-tokens", body: bodyString)
            switch result {
            case .success:
                AdaptiveLogger.log(tag: "Messaging", message: "FCM token synced successfully")
            case .failure(let error):
                AdaptiveLogger.log(tag: "Messaging", message: "FCM token sync failed: \(error)")
            }
        } catch {
            AdaptiveLogger.log(tag: "Messaging", message: "FCM token encode failed: \(error)")
        }
    }

    /// Posts notification status to /notification-status.
    /// Fires immediately — no login required. Always includes device_id,
    /// optionally includes user_id if a user is currently authenticated.
    static func sendNotificationStatus(
        notificationId: String,
        status: String
    ) async {
        let deviceId = AdaptiveCore.shared.deviceId
        var payload: [String: Any] = [
            "eventType": status,
        ]
        do {
            let body = try JSONSerialization.data(withJSONObject: payload)
            let bodyString = String(data: body, encoding: .utf8) ?? "{}"
            let result = await AdaptiveCore.shared.post(path: "/messages/\(notificationId)/events", body: bodyString, messagingService: true)
            switch result {
            case .success:
                AdaptiveLogger.log(tag: "Messaging", message: "Notification status '\(status)' sent for id=\(notificationId)")
            case .failure(let error):
                AdaptiveLogger.log(tag: "Messaging", message: "Notification status '\(status)' failed: \(error)")
            }
        } catch {
            AdaptiveLogger.log(tag: "Messaging", message: "Notification status encode failed: \(error)")
        }
    }
}
#endif
