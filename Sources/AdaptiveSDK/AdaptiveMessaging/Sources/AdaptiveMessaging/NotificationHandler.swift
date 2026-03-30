#if os(iOS)
import UserNotifications

final class NotificationHandler {
    
    static let shared = NotificationHandler()
    private var channelCreated = false
    private let channelId = "adaptive_channel"
    private let channelName = "Adaptive Notifications"
    private let channelDesc = "Notifications for adaptive messages"
    
    private init() {}
    
    private func createNotificationCategory() {
        guard !channelCreated else { return }
        channelCreated = true
        
        let category = UNNotificationCategory(
            identifier: channelId,
            actions: [],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
    func showNotification(title: String, message: String) {
        createNotificationCategory()
        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else {
                print("Notification permission not granted")
                return
            }
            
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = message
            content.sound = .default
            content.categoryIdentifier = self.channelId
            
            let randomId = UUID().uuidString
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
            
            let request = UNNotificationRequest(identifier: randomId, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Failed to show notification: \(error)")
                }
            }
        }
    }

}
#endif
