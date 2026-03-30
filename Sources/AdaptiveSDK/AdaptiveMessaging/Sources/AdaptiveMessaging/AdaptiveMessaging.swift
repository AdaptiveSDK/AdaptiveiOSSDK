#if os(iOS)
import Foundation

final class AdaptiveMessaging {
    static let shared = AdaptiveMessaging()
    
    func updateFCMToken (token : String)async{
        await MessagingRepository.updateFCMToken(token: token)
    }
    
    func isAdaptiveNotification(data: String) -> Bool {
        guard let jsonData = data.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return false
        }
        return String(describing: jsonObject["source"]) == "adaptive"
    }
    
    func showNotitication(){
        NotificationHandler.shared.showNotification(title: "Hello", message: "This is an adaptive message")

    }
}
#endif
