import Foundation


internal final class InternalHttpClient {

    internal static let baseURL = "https://beta.adlearning.api.aladwaa.com/"
    internal static let apiKey  = "-v1DJgexVnhfpdRw0v3ZUaszqwg_GOf-tdp282u-B7g3AzFugPf__Q=="

    private let apiKey   : String = InternalHttpClient.apiKey
    private let baseURL  : String = InternalHttpClient.baseURL
    private let session  : URLSession
    private let queue    : PersistentRequestQueue
    private let observer : NetworkObserver
    private let processor: QueueProcessor

    init(debug: Bool) {
        let config   = URLSessionConfiguration.default
        config.timeoutIntervalForRequest  = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)

        self.queue    = PersistentRequestQueue()
        self.observer = NetworkObserver()

        var processorRef: QueueProcessor!
        processorRef = QueueProcessor(
            queue           : queue,
            networkObserver : observer,
            executeRequest  : { [session = self.session, apiKey = self.apiKey] queued in
                let result = await Self.executeNow(
                    queued  : queued,
                    session : session,
                    apiKey  : apiKey
                )
                if case .success = result { return true }
                return false
            }
        )
        self.processor = processorRef
        self.processor.start()
    }

    func post(path: String, body: String) async -> Result<String, Error> {
        let fullURL  = baseURL + path
        let queued   = QueuedRequest(url: fullURL, method: "POST", body: body)

        guard observer.isCurrentlyConnected else {
            AdaptiveLogger.log(tag: "HttpClient", message: "Offline — queuing POST \(fullURL)")
            queue.push(queued)
            return .failure(HttpClientError.offline)
        }

        let result = await Self.executeNow(
            queued : queued,
            session: session,
            apiKey : apiKey
        )

        if case .failure = result {
            AdaptiveLogger.log(tag: "HttpClient", message: "POST failed — queuing for retry: \(fullURL)")
            queue.push(queued)
        }

        return result
    }

    func get(path: String) async -> Result<String, Error> {
        let fullURL = baseURL + path
        let queued  = QueuedRequest(url: fullURL, method: "GET")
        return await Self.executeNow(
            queued : queued,
            session: session,
            apiKey : apiKey
        )
    }

    func clearQueue() {
        queue.clear()
        AdaptiveLogger.log(tag: "HttpClient", message: "Queue cleared on logout.")
    }

    func shutdown() {
        processor.stop()
    }


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



internal enum HttpClientError: LocalizedError {
    case offline
    case invalidURL(String)
    case httpError(Int, String)
    case notInitialized
    case noUser

    var errorDescription: String? {
        switch self {
        case .offline:               return "Device is offline. Request has been queued."
        case .invalidURL(let url):   return "Invalid URL: \(url)"
        case .httpError(let c, let b): return "HTTP \(c): \(b)"
        case .notInitialized:        return "AdaptiveCore has not been initialized. Call AdaptiveCore.initialize() first."
        case .noUser:                return "No logged-in user. Call AdaptiveCore.login() first."
        }
    }
}
