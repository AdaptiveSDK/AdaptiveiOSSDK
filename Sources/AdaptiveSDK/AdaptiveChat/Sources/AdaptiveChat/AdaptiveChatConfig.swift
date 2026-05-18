#if canImport(UIKit)
import UIKit

/// Configuration for the Adaptive Chat UI.
public struct AdaptiveChatConfig {
    public let primaryColor: UIColor
    public let accentColor: UIColor
    public let backgroundColor: UIColor
    public let subject: String
    public let topic: String

    public static let `default` = AdaptiveChatConfig(
        primaryColor: UIColor(red: 15/255, green: 118/255, blue: 110/255, alpha: 1), // #0F766E
        accentColor: UIColor(red: 245/255, green: 158/255, blue: 11/255, alpha: 1),  // #F59E0B
        backgroundColor: UIColor(red: 255/255, green: 251/255, blue: 245/255, alpha: 1), // #FFFBF5
        subject: "Math",
        topic: "Fractions"
    )

    public init(primaryColor: UIColor, accentColor: UIColor, backgroundColor: UIColor, subject: String, topic: String) {
        self.primaryColor = primaryColor
        self.accentColor = accentColor
        self.backgroundColor = backgroundColor
        self.subject = subject
        self.topic = topic
    }
}
#endif
