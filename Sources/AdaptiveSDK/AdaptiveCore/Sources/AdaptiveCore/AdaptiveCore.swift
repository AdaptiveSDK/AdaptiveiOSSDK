public final class AdaptiveCore {
    nonisolated(unsafe) public static let shared = AdaptiveCore()

    private var options    : AdaptiveOptions?    = nil
    private var httpClient : InternalHttpClient? = nil
    public  var currentUser: AdaptiveUser?       = nil

    // ── Login listeners ───────────────────────────────────────────────────────
    // Modules register here to be notified when a user successfully logs in.
    // This enables the store-and-forward pattern (e.g. flushing a pending push
    // token that was received before the user authenticated).
    private var loginListeners: [(AdaptiveUser) -> Void] = []

    public func addLoginListener(_ listener: @escaping (AdaptiveUser) -> Void) {
        loginListeners.append(listener)
    }
    // ─────────────────────────────────────────────────────────────────────────

    private init() {}

    public func initialize(clientId: String, debug: Bool) {
        options    = AdaptiveOptions(clientId: clientId, debug: debug)
        httpClient = InternalHttpClient(debug: debug)
        AdaptiveLogger.debug = debug
        AdaptiveLogger.log(tag: "AdaptiveCore", message: "SDK initialized")
    }

    public var clientId: String? { options?.clientId }

    /// The permanent device identifier for this app installation.
    /// Generated once (UUID) and persisted in the Keychain so the backend can
    /// track the device regardless of authentication state.
    public var deviceId: String { KeychainHelper.getOrCreateDeviceId() }

    public func post(path: String, body: String) async -> Result<String, Error> {
        guard let client = httpClient else {
            return .failure(AdaptiveError("not_initialized", "Call AdaptiveCore.initialize() first"))
        }
        return await client.post(path: path, body: body)
    }

    public func login(userId: String, userName: String, userEmail: String, phoneNumber: String = "", userGrade: UserGrade? = nil) {
        checkInitialization()
        // Guard: listeners must only fire once per session.
        // If a user is already logged in, skip the broadcast and warn.
        guard currentUser == nil else {
            AdaptiveLogger.log(tag: "AdaptiveCore", message: "login() called while a session is already active – ignoring. Call logout() first.")
            return
        }
        if httpClient == nil {
            httpClient = InternalHttpClient(debug: options?.debug ?? false)
        }
        let user = AdaptiveUser(userId: userId, userEmail: userEmail, userName: userName, phoneNumber: phoneNumber, userGrade: userGrade)
        currentUser = user
        loginListeners.forEach { $0(user) }
        AdaptiveLogger.log(tag: "AdaptiveCore", message: "User Login successfully")
    }

    public func logout() {
        checkInitialization()
        httpClient?.clearQueue()
        httpClient?.shutdown()
        httpClient = nil
        currentUser = nil
        AdaptiveLogger.log(tag: "AdaptiveCore", message: "User Logout successfully")
    }

    public func checkInitialization() {
        guard options != nil else {
            fatalError("You Must call AdaptiveCore.initialize() first")
        }
    }
}
