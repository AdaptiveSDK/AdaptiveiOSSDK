import Foundation

/// Represents a saved chat conversation session for the history drawer.
public struct ChatSession: Identifiable {
    public let id: String
    public let title: String
    public let lastMessage: String
    public let timestamp: Date
    public var isActive: Bool

    public init(id: String = UUID().uuidString, title: String, lastMessage: String, timestamp: Date = Date(), isActive: Bool = false) {
        self.id = id
        self.title = title
        self.lastMessage = lastMessage
        self.timestamp = timestamp
        self.isActive = isActive
    }
}
