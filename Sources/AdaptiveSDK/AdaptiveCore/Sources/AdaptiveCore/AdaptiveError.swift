public struct AdaptiveError: Error {
    public let code: String
    public let message: String

    public init(_ code: String, _ message: String) {
        self.code = code
        self.message = message
    }
}
