#if os(iOS)
import Foundation
import AdaptiveCore

internal class MessagingRepository {

    // Sends (or refreshes) the push token for this device.
    //
    // Parameters:
    //   token  -- current APNs / FCM push token.
    //   userId -- the authenticated user ID, or nil when the token is being
    //             registered before the user has logged in (pre-login
    //             store-and-forward pattern).
    //
    // The deviceId is always resolved from KeychainHelper so the backend can
    // track the device regardless of authentication state -- the same approach
    // used by WebEngage, FreshChat, and CleverTap.
    static func updateFCMToken(token: String, userId: String?) async {
        let deviceId = KeychainHelper.getOrCreateDeviceId()

        do {
            var payload: [String: Any] = [
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
}
#endif
