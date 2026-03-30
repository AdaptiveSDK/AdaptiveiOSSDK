public final class AdaptiveCore {
    nonisolated(unsafe) public static let shared = AdaptiveCore()

    private var options    : AdaptiveOptions?    = nil
    private var httpClient : InternalHttpClient? = nil
    public  var currentUser: AdaptiveUser?       = nil

    private init() {}

    public func initialize(clientId: String, debug: Bool) {
        options    = AdaptiveOptions(clientId: clientId, debug: debug)
        httpClient = InternalHttpClient(debug: debug)
        AdaptiveLogger.debug = debug
        AdaptiveLogger.log(tag: "AdaptiveCore", message: "SDK initialized")
    }

    public var clientId: String? { options?.clientId }

    public func post(path: String, body: String) async -> Result<String, Error> {
        guard let client = httpClient else {
            return .failure(AdaptiveError("not_initialized", "Call AdaptiveCore.initialize() first"))
        }
        return await client.post(path: path, body: body)
    }

    public func login(userId: String, userName: String, userEmail: String) {
        checkInitialization()
        currentUser = AdaptiveUser(userId: userId, userEmail: userEmail, userName: userName)
        AdaptiveLogger.log(tag: "AdaptiveCore", message: "User Login successfully \(currentUser?.userId ?? "")")
    }

    public func logout() {
        checkInitialization()
        httpClient?.clearQueue()
        currentUser = nil
        AdaptiveLogger.log(tag: "AdaptiveCore", message: "User Logout successfully")
    }

    public func checkInitialization() {
        guard options != nil else {
            fatalError("You Must call AdaptiveCore.initialize() first")
        }
    }
}
