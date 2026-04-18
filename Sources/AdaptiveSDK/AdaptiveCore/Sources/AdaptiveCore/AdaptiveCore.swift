import Foundation

public final class AdaptiveCore {
    nonisolated(unsafe) public static let shared = AdaptiveCore()

    private var options    : AdaptiveOptions?    = nil
    private var httpClient : InternalHttpClient? = nil
    public  var currentUser: AdaptiveUser?       = nil

    // ── Login listeners ─────────────────────────────────────────────────────────
    // Modules register here to be notified when a user successfully logs in.
    // This enables the store-and-forward pattern (e.g. flushing a pending push
    // token that was received before the user authenticated).
    private var loginListeners: [(AdaptiveUser) -> Void] = []
    private let loginLock = NSLock()

    public func addLoginListener(_ listener: @escaping (AdaptiveUser) -> Void) {
        loginListeners.append(listener)
    }
    // ───────────────────────────────────────────────────────────────────────────

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
        loginLock.lock()
        defer { loginLock.unlock() }
        // Guard: loginLock ensures only one thread executes this at a time,
        // so currentUser == nil is a reliable once-per-session check.
        guard currentUser == nil else {
            AdaptiveLogger.log(tag: "AdaptiveCore", message: "login() already called for this session – ignoring. Call logout() first.")
            return
        }
        if httpClient == nil {
            httpClient = InternalHttpClient(debug: options?.debug ?? false)
        }
        let user = AdaptiveUser(userId: userId, userEmail: userEmail, userName: userName, phoneNumber: phoneNumber, userGrade: userGrade)
        currentUser = user
        loginListeners.forEach { $0(user) }
        logAppLaunchEvent(userId: userId, userEmail: userEmail, userName: userName, phoneNumber: phoneNumber, userGrade: userGrade)
        AdaptiveLogger.log(tag: "AdaptiveCore", message: "User Login successfully")
    }

    private func logAppLaunchEvent(userId: String, userEmail: String, userName: String, phoneNumber: String, userGrade: UserGrade?) {
        Task { [weak self] in
            guard let self else { return }
            var dict: [String: Any] = [
                "userId": userId, "userEmail": userEmail,
                "userFullName": userName, "phoneNumber": phoneNumber,
                "clientId": self.clientId ?? "",
                "eventTimestamp": Int(Date().timeIntervalSince1970)
            ]
            if let g = userGrade { dict["UserGrade"] = g.rawValue }
            let body = String(data: (try? JSONSerialization.data(withJSONObject: dict)) ?? Data(), encoding: .utf8) ?? "{}"
            _ = await self.post(path: "events/app-launch", body: body)
        }
    }

    public func logout() {
        checkInitialization()
        currentUser = nil
        lastPostedDeviceToken = nil
        httpClient?.clearQueue()
        httpClient?.shutdown()
        httpClient = nil
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

    // ── Shared device-token posting ────────────────────────────────────────────
    // Centralised here so that both AdaptiveAnalytics (post-registration) and
    // AdaptiveMessaging (login-flush) can call it without duplicating
    // KeychainHelper / payload construction logic.
    //
    // A session-level dedup guard prevents the same userId+token pair from
    // being posted twice in the same session (e.g. when both listeners fire on
    // the same login() call).
    // ───────────────────────────────────────────────────────────────────────────
    private var lastPostedDeviceToken: (userId: String, token: String)? = nil

    /// Posts the latest FCM token to `/device-tokens` for the given `userId`.
    ///
    /// Returns `true` if the call was made, `false` if skipped (no token
    /// available, or the same user+token pair was already posted this session).
    @discardableResult
    public func postDeviceToken(userId: String) async -> Bool {
        guard let token = getLatestFcmToken() else {
            AdaptiveLogger.log(tag: "AdaptiveCore", message: "No FCM token available – skipping device-token call")
            return false
        }
        // Dedup: don't post the same user+token pair twice in one session
        if let last = lastPostedDeviceToken, last.userId == userId, last.token == token {
            AdaptiveLogger.log(tag: "AdaptiveCore", message: "Device token already posted for user \(userId) – skipping duplicate")
            return false
        }
        let devId = KeychainHelper.getOrCreateDeviceId()
        let payload: [String: Any] = ["userId": userId, "deviceId": devId, "token": token]
        guard let body = String(data: (try? JSONSerialization.data(withJSONObject: payload)) ?? Data(), encoding: .utf8) else { return false }
        _ = await post(path: "/device-tokens", body: body)
        lastPostedDeviceToken = (userId, token)
        AdaptiveLogger.log(tag: "AdaptiveCore", message: "Device token sent for user \(userId)")
        return true
    }
    // ───────────────────────────────────────────────────────────────────────────
}
