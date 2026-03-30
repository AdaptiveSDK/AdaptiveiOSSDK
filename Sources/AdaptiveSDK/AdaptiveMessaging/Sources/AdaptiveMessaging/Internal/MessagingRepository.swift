#if os(iOS)
import Foundation
import AdaptiveCore

internal class MessagingRepository {

    static func updateFCMToken(token: String) async {
        guard let currentUser = AdaptiveCore.shared.currentUser else {
            fatalError("You must use AdaptiveCore.login() first")
        }

        do {
            let body = try JSONEncoder().encode([
                "fcmToken": token,
                "userId": currentUser.userId
            ])
            let bodyString = String(data: body, encoding: .utf8) ?? "{}"

            let result = await AdaptiveCore.shared.post(path: "moodle/update-fcm", body: bodyString)
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
}
#endif
