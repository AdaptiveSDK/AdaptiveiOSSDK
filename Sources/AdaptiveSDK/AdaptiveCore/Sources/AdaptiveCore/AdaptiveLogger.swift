public final class AdaptiveLogger {
    nonisolated(unsafe) public static let shared = AdaptiveLogger()
    nonisolated(unsafe) static var debug : Bool = false

    public static func log(tag: String, message: String) {
        if debug {
            print("[Adaptive][\(tag)]  \(message)")
        }
    }

    func debug(_ tag: String, _ message: String) {
        AdaptiveLogger.log(tag: tag, message: message)
    }

    func warning(_ tag: String, _ message: String) {
        AdaptiveLogger.log(tag: tag, message: message)
    }

    func error(_ tag: String, _ message: String) {
        AdaptiveLogger.log(tag: tag, message: message)
    }
}
