#if canImport(UIKit)
import UIKit

/// Main entry point for the Adaptive Chat SDK on iOS.
/// Provides a pre-built AI Coach chat experience with survey flow,
/// quiz (True/False), flashcards, step-by-step explanations, and chat history.
public final class AdaptiveChat {
    nonisolated(unsafe) public static let shared = AdaptiveChat()

    private init() {}

    /// Present the AI Coach chat screen from the given view controller.
    /// - Parameters:
    ///   - from: The presenting UIViewController
    ///   - config: Optional configuration for theming and behavior
    public func presentChat(from viewController: UIViewController, config: AdaptiveChatConfig = .default) {
        let chatVC = AdaptiveChatViewController()
        chatVC.config = config
        chatVC.modalPresentationStyle = .fullScreen
        viewController.present(chatVC, animated: true)
    }

    /// Push the AI Coach chat screen onto a navigation stack.
    /// - Parameters:
    ///   - navigationController: The navigation controller to push onto
    ///   - config: Optional configuration for theming and behavior
    public func pushChat(onto navigationController: UINavigationController, config: AdaptiveChatConfig = .default) {
        let chatVC = AdaptiveChatViewController()
        chatVC.config = config
        navigationController.pushViewController(chatVC, animated: true)
    }
}
#endif
