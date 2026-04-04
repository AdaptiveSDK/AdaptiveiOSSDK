import Foundation

internal final class InternalHttpClient {

    internal static let baseURL = "https://beta.adlearning.api.aladwaa.com/"

    private let apiKey   : String = Secrets.functionCode
    private let baseURL  : String = InternalHttpClient.baseURL
    private let session  : URLSession
    private let queue    : PersistentRequestQueue
    private let observer : NetworkObserver
    private let processor: QueueProcessor

    private static let maxInlineRetries = 3
    private static let retryDelayNs: UInt64 = 1_000_000_000 // 1 s per attempt

    init(debug: Bool) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest  = 30
        config.timeoutIntervalForResource = 60
        self.session  = URLSession(configuration: config)
        self.queue    = PersistentRequestQueue()
        self.observer = NetworkObserver()

        var processorRef: QueueProcessor!
        processorRef = QueueProcessor(
            queue           : queue,
            networkObserver : observer,
            executeRequest  : { [session = self.session, apiKey = self.apiKey] queued in
                let result = await Self.executeNow(queued: queued, session: session, apiKey: apiKey)
                if case .success = result { return true }
                return false
            }
        )
        self.processor = processorRef
        self.processor.start()
    }

    // MARK: – Public API

    func post(path: String, body: String) async -> Result<String, Error> {
        let fullURL = baseURL + path
        let queued  = QueuedRequest(url: fullURL, method: "POST", body: body)

        guard observer.isCurrentlyConnected else {
            AdaptiveLogger.log(tag: "HttpClient", message: "Offline — queuing POST \(fullURL)")
            queue.push(queued)
            return .failure(HttpClientError.offline)
        }

        let result = await executeWithRetry(queued: queued)

        if case .failure = result {
            AdaptiveLogger.log(tag: "HttpClient", message: "All retries exhausted — queuing POST \(fullURL)")
            queue.push(queued)
        }

        return result
    }

    func get(path: String) async -> Result<String, Error> {
        let fullURL = baseURL + path
        let queued  = QueuedRequest(url: fullURL, method: "GET")

        guard observer.isCurrentlyConnected else {
            AdaptiveLogger.log(tag: "HttpClient", message: "Offline — skipping GET \(fullURL)")
            return .failure(HttpClientError.offline)
        }

        return await executeWithRetry(queued: queued)
    }

    func clearQueue() {
        queue.clear()
        AdaptiveLogger.log(tag: "HttpClient", message: "Queue cleared on logout.")
    }

    func shutdown() {
        processor.stop()
    }

    // MARK: – Retry logic

    /// Attempts the request up to `maxInlineRetries` times.
    /// Checks connectivity **before each attempt**:
    ///  - Offline → stops immediately and returns `.failure(.offline)` so the
    ///    caller can queue the request.
    ///  - Attempt succeeds → returns `.success` right away.
    ///  - Attempt fails but still online → waits (1 s × attempt) then retries.
    private func executeWithRetry(queued: QueuedRequest) async -> Result<String, Error> {
        var lastResult: Result<String, Error> = .failure(HttpClientError.offline)

        for attempt in 1...Self.maxInlineRetries {
            guard observer.isCurrentlyConnected else {
                AdaptiveLogger.log(
                    tag: "HttpClient",
                    message: "Connection lost before attempt \(attempt)/\(Self.maxInlineRetries) — aborting retries"
                )
                return .failure(HttpClientError.offline)
            }

            AdaptiveLogger.log(tag: "HttpClient", message: "Attempt \(attempt)/\(Self.maxInlineRetries) → \(queued.url)")
            lastResult = await Self.executeNow(queued: queued, session: session, apiKey: apiKey)

            if case .success = lastResult {
                AdaptiveLogger.log(tag: "HttpClient", message: "Request succeeded on attempt \(attempt)")
                return lastResult
            }

            AdaptiveLogger.log(
                tag: "HttpClient",
                message: "Attempt \(attempt)/\(Self.maxInlineRetries) failed: \(lastResult)"
            )

            if attempt < Self.maxInlineRetries {
                let waitNs = Self.retryDelayNs * UInt64(attempt)
                AdaptiveLogger.log(tag: "HttpClient", message: "Waiting \(attempt)s before next retry…")
                try? await Task.sleep(nanoseconds: waitNs)
            }
        }

        return lastResult
    }

    // MARK: – Execution

    private static func executeNow(
        queued  : QueuedRequest,
        session : URLSession,
        apiKey  : String
    ) async -> Result<String, Error> {

        guard let url = URL(string: queued.url) else {
            return .failure(HttpClientError.invalidURL(queued.url))
        }

        var components        = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        var queryItems        = components.queryItems ?? []
        queryItems.append(URLQueryItem(name: "code", value: apiKey))
        components.queryItems = queryItems

        guard let finalURL = components.url else {
            return .failure(HttpClientError.invalidURL(queued.url))
        }

        var urlRequest        = URLRequest(url: finalURL)
        urlRequest.httpMethod = queued.method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body = queued.body {
            urlRequest.httpBody = body.data(using: .utf8)
        }

        do {
            let (data, response) = try await session.data(for: urlRequest)
            let httpResponse     = response as! HTTPURLResponse
            let responseBody     = String(data: data, encoding: .utf8) ?? ""

            AdaptiveLogger.log(tag: "HttpClient", message: "\(queued.method) \(queued.url) → \(httpResponse.statusCode)")

            if (200...299).contains(httpResponse.statusCode) {
                return .success(responseBody)
            } else {
                return .failure(HttpClientError.httpError(httpResponse.statusCode, responseBody))
            }
        } catch {
            AdaptiveLogger.log(tag: "HttpClient", message: "\(queued.method) \(queued.url) failed: \(error)")
            return .failure(error)
        }
    }
}

// MARK: – Errors

internal enum HttpClientError: LocalizedError {
    case offline
    case invalidURL(String)
    case httpError(Int, String)
    case notInitialized
    case noUser

    var errorDescription: String? {
        switch self {
        case .offline:                  return "Device is offline. Request has been queued."
        case .invalidURL(let url):      return "Invalid URL: \(url)"
        case .httpError(let c, let b):  return "HTTP \(c): \(b)"
        case .notInitialized:           return "AdaptiveCore has not been initialized. Call AdaptiveCore.initialize() first."
        case .noUser:                   return "No logged-in user. Call AdaptiveCore.login() first."
}
