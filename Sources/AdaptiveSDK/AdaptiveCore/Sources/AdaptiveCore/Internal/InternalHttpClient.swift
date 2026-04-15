import Foundation
import CryptoKit

internal final class InternalHttpClient {

    internal static let baseURL = "https://beta.adlearning.api.aladwaa.com/"

    // TODO: move to a server-side token exchange before production
    private let apiKey   : String = "-v1DJgexVnhfpdRw0v3ZUaszqwg_GOf-tdp282u-B7g3AzFugPf__Q=="
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
        self.session  = URLSession(configuration: config, delegate: CertificatePinningDelegate(), delegateQueue: nil)
        self.queue    = PersistentRequestQueue()
        self.observer = NetworkObserver()

        var processorRef: QueueProcessor!
        processorRef = QueueProcessor(
            queue           : queue,
            networkObserver : observer,
            executeRequest  : { [session = self.session, apiKey = self.apiKey] queued in
                let (result, retryAfterSec) = await Self.executeNow(queued: queued, session: session, apiKey: apiKey)
                if case .success = result { return (true, nil) }
                return (false, retryAfterSec)
            }
        )
        self.processor = processorRef
        self.processor.start()
    }

    // MARK: - Public API

    func post(path: String, body: String) async -> Result<String, Error> {
        let fullURL = baseURL + path
        let queued  = QueuedRequest(url: fullURL, method: "POST", body: body)

        guard observer.isCurrentlyConnected else {
            AdaptiveLogger.log(tag: "HttpClient", message: "Offline - queuing POST \(fullURL)")
            queue.push(queued)
            return .failure(HttpClientError.offline)
        }

        let result = await executeWithRetry(queued: queued)

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

        return await executeWithRetry(queued: queued)
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
            let (result429, retryAfterSec) = await Self.executeNow(queued: queued, session: session, apiKey: apiKey)
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
        queued  : QueuedRequest,
        session : URLSession,
        apiKey  : String
    ) async -> (Result<String, Error>, TimeInterval?) {

        guard let url = URL(string: queued.url) else {
            return (.failure(HttpClientError.invalidURL(queued.url)), nil)
        }

        var components        = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        var queryItems        = components.queryItems ?? []
        queryItems.append(URLQueryItem(name: "code", value: apiKey))
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
}

    private static func withJitter(base: UInt64) -> UInt64 {
        let factor = Double.random(in: 0.8...1.2)
        return UInt64(Double(base) * factor)
    }
}

// MARK: - Certificate Pinning
// TODO: Replace pinnedHashes with real SHA-256 SPKI fingerprints before shipping.
private final class CertificatePinningDelegate: NSObject, URLSessionDelegate {
    private let pinnedHashes: Set<String> = [
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
        "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=",
    ]
    private static let rsaHeader = Data([0x30,0x82,0x01,0x22,0x30,0x0d,0x06,0x09,0x2a,0x86,0x48,0x86,0xf7,0x0d,0x01,0x01,0x01,0x05,0x00,0x03,0x82,0x01,0x0f,0x00])
    private static let ecHeader  = Data([0x30,0x59,0x30,0x13,0x06,0x07,0x2a,0x86,0x48,0xce,0x3d,0x02,0x01,0x06,0x08,0x2a,0x86,0x48,0xce,0x3d,0x03,0x01,0x07,0x03,0x42,0x00])
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else { completionHandler(.performDefaultHandling, nil); return }
        var cfError: CFError?
        guard SecTrustEvaluateWithError(serverTrust, &cfError) else { completionHandler(.cancelAuthenticationChallenge, nil); return }
        guard let leafCert = SecTrustGetCertificateAtIndex(serverTrust, 0), let publicKey = SecCertificateCopyKey(leafCert), let keyData = SecKeyCopyExternalRepresentation(publicKey, nil) as Data? else { completionHandler(.cancelAuthenticationChallenge, nil); return }
        let attrs = SecKeyCopyAttributes(publicKey) as? [String: Any]
        let isRSA = (attrs?[kSecAttrKeyType as String] as? String) == (kSecAttrKeyTypeRSA as String)
        let spki  = (isRSA ? Self.rsaHeader : Self.ecHeader) + keyData
        let hash  = Data(SHA256.hash(data: spki)).base64EncodedString()
        if pinnedHashes.contains(hash) { completionHandler(.useCredential, URLCredential(trust: serverTrust)) }
        else { completionHandler(.cancelAuthenticationChallenge, nil) }
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
