import Foundation
import CryptoKit

// MARK: - Request Serializer

/// Serializes async operations so they execute one at a time.
/// Uses a serial OperationQueue + DispatchSemaphore — fully compatible with
/// the project's iOS 12 deployment target. No Task stored properties, no
/// actor, no CheckedContinuation.
///
/// How it works:
///   1. Each `serialize` call enqueues a blocking NSBlockOperation on a
///      serial queue (maxConcurrentOperationCount = 1), so operations never
///      overlap.
///   2. Inside the operation a DispatchSemaphore blocks the queue thread
///      until the async `work` closure signals completion.
///   3. The caller resumes via an UnsafeContinuation once the result is ready.
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
private final class RequestSerializer {

    private let serialQueue: OperationQueue = {
        let q = OperationQueue()
        q.maxConcurrentOperationCount = 1
        q.name = "com.adaptivesdk.http-serializer"
        return q
    }()

    func serialize<T>(_ work: @escaping () async -> T) async -> T {
        await withUnsafeContinuation { continuation in
            serialQueue.addOperation {
                let semaphore = DispatchSemaphore(value: 0)
                // Mutable captured state — safe because the semaphore ensures
                // the write completes before the read below.
                var result: T?
                Task {
                    result = await work()
                    semaphore.signal()
                }
                semaphore.wait()
                continuation.resume(returning: result!)
            }
        }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
internal final class InternalHttpClient {

    internal static let baseURL = "https://beta.adlearning.api.aladwaa.com/"

    // TODO: move to a server-side token exchange before production
    private let apiKey   : String = "-v1DJgexVnhfpdRw0v3ZUaszqwg_GOf-tdp282u-B7g3AzFugPf__Q=="
    private let baseURL          : String = InternalHttpClient.baseURL

    private let messagingBaseURL  : String = "https://beta.adlearningmessaging.api.aladwaa.com/"
    private let messagingApiKey   : String = "IMulRu1Sbh7_zYc47JYBy8ZUdrWDNPOIB-ZY8-6P7ew_AzFuQnkkDw=="
    private let session  : URLSession
    private let queue    : PersistentRequestQueue
    private let observer : NetworkObserver
    private let processor: QueueProcessor

    /** Ensures requests are dispatched one at a time (no concurrent HTTP calls). */
    private let requestSerializer = RequestSerializer()

    private static let maxInlineRetries = 3
    private static let retryDelayNs: UInt64 = 1_000_000_000 // 1 s per attempt

    init(debug: Bool) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest  = 30
        config.timeoutIntervalForResource = 60
        self.session  = URLSession(configuration: config, delegate: TrustAllCertsDelegate(), delegateQueue: nil)
        self.queue    = PersistentRequestQueue()
        self.observer = NetworkObserver()

        var processorRef: QueueProcessor!
        processorRef = QueueProcessor(
            queue           : queue,
            networkObserver : observer,
            executeRequest  : { [session = self.session, apiKey = self.apiKey, messagingApiKey = self.messagingApiKey] queued in
                let (result, retryAfterSec) = await Self.executeNow(queued: queued, session: session, apiKey: apiKey, messagingApiKey: messagingApiKey)
                if case .success = result { return (true, nil) }
                return (false, retryAfterSec)
            }
        )
        self.processor = processorRef
        self.processor.start()
    }

    // MARK: - Public API

    func post(path: String, body: String, messagingService: Bool = false) async -> Result<String, Error> {
        let resolvedBaseURL = messagingService ? messagingBaseURL : baseURL
        let fullURL = resolvedBaseURL + path
        let queued  = QueuedRequest(url: fullURL, method: "POST", body: body)

        guard observer.isCurrentlyConnected else {
            AdaptiveLogger.log(tag: "HttpClient", message: "Offline - queuing POST \(fullURL)")
            queue.push(queued)
            return .failure(HttpClientError.offline)
        }

        let result = await requestSerializer.serialize {
            await self.executeWithRetry(queued: queued)
        }

        if case .failure = result {
            AdaptiveLogger.log(tag: "HttpClient", message: "All retries exhausted - queuing POST \(fullURL)")
            queue.push(queued)
        }

        return result
    }

    func get(path: String) async -> Result<String, Error> {
        let fullURL = baseURL + path
        let queued  = QueuedRequest(url: fullURL, method: "GET")

        guard observer.isCurrentlyConnected else {
            AdaptiveLogger.log(tag: "HttpClient", message: "Offline - skipping GET \(fullURL)")
            return .failure(HttpClientError.offline)
        }

        return await requestSerializer.serialize {
            await self.executeWithRetry(queued: queued)
        }
    }

    func clearQueue() {
        queue.clear()
        AdaptiveLogger.log(tag: "HttpClient", message: "Queue cleared on logout.")
    }

    func shutdown() {
        processor.stop()
    }

    // MARK: - Retry logic

    private func executeWithRetry(queued: QueuedRequest) async -> Result<String, Error> {
        let messagingApiKey = self.messagingApiKey
        var lastResult: Result<String, Error> = .failure(HttpClientError.offline)

        for attempt in 1...Self.maxInlineRetries {
            guard observer.isCurrentlyConnected else {
                AdaptiveLogger.log(
                    tag: "HttpClient",
                    message: "Connection lost before attempt \(attempt)/\(Self.maxInlineRetries) - aborting retries"
                )
                return .failure(HttpClientError.offline)
            }

            AdaptiveLogger.log(tag: "HttpClient", message: "Attempt \(attempt)/\(Self.maxInlineRetries) -> \(queued.url)")
            let (result429, retryAfterSec) = await Self.executeNow(queued: queued, session: session, apiKey: apiKey, messagingApiKey: messagingApiKey)
            lastResult = result429

            if case .success = lastResult { AdaptiveLogger.log(tag: "HttpClient", message: "Request succeeded"); return lastResult }

            if let retryAfter = retryAfterSec {
                let waitNs = Self.withJitter(base: UInt64(retryAfter * 1_000_000_000))
                try? await Task.sleep(nanoseconds: waitNs)
                continue
            }

            AdaptiveLogger.log(tag: "HttpClient", message: "Attempt \(attempt)/\(Self.maxInlineRetries) failed: \(lastResult)")

            if attempt < Self.maxInlineRetries {
                let waitNs = Self.withJitter(base: Self.retryDelayNs * UInt64(attempt))
                try? await Task.sleep(nanoseconds: waitNs)
            }
        }

        return lastResult
    }

    // MARK: - Execution

    private static func executeNow(
        queued          : QueuedRequest,
        session         : URLSession,
        apiKey          : String,
        messagingApiKey : String = ""
    ) async -> (Result<String, Error>, TimeInterval?) {

        guard let url = URL(string: queued.url) else {
            return (.failure(HttpClientError.invalidURL(queued.url)), nil)
        }

        var components        = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        var queryItems        = components.queryItems ?? []
        let isMessagingRequest = url.host?.contains("adlearningmessaging") == true
        let resolvedApiKey = isMessagingRequest ? messagingApiKey : apiKey
        queryItems.append(URLQueryItem(name: "code", value: resolvedApiKey))
        components.queryItems = queryItems

        guard let finalURL = components.url else {
            return (.failure(HttpClientError.invalidURL(queued.url)), nil)
        }

        var urlRequest        = URLRequest(url: finalURL)
        urlRequest.httpMethod = queued.method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body = queued.body {
            urlRequest.httpBody = body.data(using: .utf8)
        }

        AdaptiveLogger.log(
            tag: "HttpClient",
            message: "\n→ REQUEST\n  Method : \(queued.method)\n  URL    : \(queued.url)\n  Body   : \(queued.body ?? "(none)")"
        )

        do {
            let (data, response) = try await session.data(for: urlRequest)
            let httpResponse     = response as! HTTPURLResponse
            let responseBody     = String(data: data, encoding: .utf8) ?? ""

            AdaptiveLogger.log(
                tag: "HttpClient",
                message: "\n← RESPONSE\n  Method : \(queued.method)\n  URL    : \(queued.url)\n  Status : \(httpResponse.statusCode)\n  Body   : \(responseBody)"
            )

            if (200...299).contains(httpResponse.statusCode) {
                return (.success(responseBody), nil)
            } else if httpResponse.statusCode == 429 {
                let retryAfterSec = httpResponse.value(forHTTPHeaderField: "Retry-After").flatMap { Double($0) } ?? 60.0
                return (.failure(HttpClientError.httpError(429, responseBody)), retryAfterSec)
            } else {
                return (.failure(HttpClientError.httpError(httpResponse.statusCode, responseBody)), nil)
            }
        } catch {
            AdaptiveLogger.log(tag: "HttpClient", message: "Request Exception (\(queued.method) \(queued.url)): \(error)")
            return (.failure(error), nil)
        }
    }

    private static func withJitter(base: UInt64) -> UInt64 {
        let factor = Double.random(in: 0.8...1.2)
        return UInt64(Double(base) * factor)
    }
}

// MARK: - Certificate Pinning
// TODO: Replace pinnedHashes with real SHA-256 SPKI fingerprints before shipping.
private final class TrustAllCertsDelegate: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        completionHandler(.useCredential, URLCredential(trust: serverTrust))
    }
}

// MARK: - Errors

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
    }
}
