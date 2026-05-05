import Foundation

public final class AdaptiveCore {
    nonisolated(unsafe) public static let shared = AdaptiveCore()

    private var options    : AdaptiveOptions? = nil
    // Stored as AnyObject so the class declaration itself has no iOS 13+
    // dependency. Accessed only through the @available helper below.
    private var _httpClient: AnyObject?       = nil
    public  var currentUser: AdaptiveUser?    = nil

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    private var httpClient: InternalHttpClient? {
        get { _httpClient as? InternalHttpClient }
        set { _httpClient = newValue }
    }

    // ── Login listeners ─────────────────────────────────────────────────────────
    // Modules register here to be notified when a user successfully logs in.
    // This enables the store-and-forward pattern (e.g. flushing a pending push
    // token that was received before the user authenticated).
    private var loginListeners: [(AdaptiveUser) -> Void] = []
    private let loginLock = NSLock()

    public func addLoginListener(_ listener: @escaping (AdaptiveUser) -> Void) {
        loginListeners.append(listener)
        // Replay: if login() already fired, invoke immediately for late-initializing modules.
        if let user = currentUser { listener(user) }
    }
    // ───────────────────────────────────────────────────────────────────────────

    // ── Registration listeners ────────────────────────────────────────────────────────────
    // Decoupled observer: Analytics fires `notifyRegistration(user)` after a
    // registration event is confirmed; Messaging subscribes and handles its
    // own FCM token posting. This avoids direct cross-module dependencies.
    private var registrationListeners: [(AdaptiveUser) -> Void] = []

    public func addRegistrationListener(_ listener: @escaping (AdaptiveUser) -> Void) {
        registrationListeners.append(listener)
    }

    public func notifyRegistration(_ user: AdaptiveUser) {
        registrationListeners.forEach { $0(user) }
    }
    // ───────────────────────────────────────────────────────────────────────────

    private init() {}

    public func initialize(clientId: String, debug: Bool) {
        options = AdaptiveOptions(clientId: clientId, debug: debug)
        AdaptiveLogger.debug = debug
        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *) {
            httpClient = InternalHttpClient(debug: debug)
        }
        AdaptiveLogger.log(tag: "AdaptiveCore", message: "SDK initialized")
    }

    public var clientId: String? { options?.clientId }

    /// The permanent device identifier for this app installation.
    /// Generated once (UUID) and persisted in the Keychain so the backend can
    /// track the device regardless of authentication state.
    public var deviceId: String { KeychainHelper.getOrCreateDeviceId() }

    public func post(path: String, body: String, messagingService: Bool = false) async -> Result<String, Error> {
        guard #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *) else {
            return .failure(AdaptiveError("unsupported_os", "AdaptiveCore requires iOS 13 or later"))
        }
        guard let client = httpClient else {
            return .failure(AdaptiveError("not_initialized", "Call AdaptiveCore.initialize() first"))
        }
        return await client.post(path: path, body: body, messagingService: messagingService)
    }

    public func login(user : AdaptiveUser) {
        checkInitialization()
        loginLock.lock()
        defer { loginLock.unlock() }
        // Guard: loginLock ensures only one thread executes this at a time,
        // so currentUser == nil is a reliable once-per-session check.
        guard currentUser == nil else {
            AdaptiveLogger.log(tag: "AdaptiveCore", message: "login() already called for this session – ignoring. Call logout() first.")
            return
        }
        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *) {
            if httpClient == nil {
                httpClient = InternalHttpClient(debug: options?.debug ?? false)
            }
        }
        currentUser = user
        loginListeners.forEach { $0(user) }
        AdaptiveLogger.log(tag: "AdaptiveCore", message: "User Login successfully")
    }

    public func logout() {
        checkInitialization()
        currentUser = nil
        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *) {
            httpClient?.clearQueue()
            httpClient?.shutdown()
            httpClient = nil
        }
        AdaptiveLogger.log(tag: "AdaptiveCore", message: "User Logout successfully")
    }

    public func checkInitialization() {
        guard options != nil else {
            fatalError("You Must call AdaptiveCore.initialize() first")
        }
    }

    // ── Shared FCM token store ───────────────────────────────────────────────
    // Both AdaptiveAnalytics and AdaptiveMessaging depend on AdaptiveCore.
    // Storing the latest FCM token here lets analytics read it after a
    // registration event without creating a cross-module dependency.
    // ───────────────────────────────────────────────────────────────────────────
    private static let fcmKey = "adaptive_latest_fcm_token"

    public func saveFcmToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: Self.fcmKey)
    }

    public func getLatestFcmToken() -> String? {
        UserDefaults.standard.string(forKey: Self.fcmKey)
    }

}
