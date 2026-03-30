#if os(iOS)
import Foundation

public final class AdaptiveMessaging {
    nonisolated(unsafe) public static let shared = AdaptiveMessaging()

    private init() {}

    public func updateFCMToken(token: String) async {
        await MessagingRepository.updateFCMToken(token: token)
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
