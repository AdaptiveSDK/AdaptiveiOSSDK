import Foundation

internal struct QueuedRequest: Codable {
    let id         : String
    let url        : String
    let method     : String
    let headers    : [String: String]
    let body       : String?
    var retryCount : Int
    let createdAt  : TimeInterval
    let maxRetries : Int

    var isExhausted: Bool {
        return retryCount >= maxRetries
    }

    init(
        id         : String           = UUID().uuidString,
        url        : String,
        method     : String,
        headers    : [String: String] = [:],
        body       : String?          = nil,
        retryCount : Int              = 0,
        createdAt  : TimeInterval     = Date().timeIntervalSince1970,
        maxRetries : Int              = 3
    ) {
        self.id         = id
        self.url        = url
        self.method     = method
        self.headers    = headers
        self.body       = body
        self.retryCount = retryCount
        self.createdAt  = createdAt
        self.maxRetries = maxRetries
    }
}
