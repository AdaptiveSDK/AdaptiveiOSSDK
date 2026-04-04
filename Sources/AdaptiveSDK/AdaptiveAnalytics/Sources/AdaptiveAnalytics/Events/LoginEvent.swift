public struct LoginEvent: Encodable {
    public let userId        : Int
    public let userEmail     : String
    public let userFullName  : String
    public let clientId      : String
    public let eventTimestamp: Int
    public let ipAddress     : String
    public let userAgent     : String
    public let productId     : Int

    public init(
        userId        : Int,
        userEmail     : String,
        userFullName  : String,
        clientId      : String,
        eventTimestamp: Int,
        ipAddress     : String,
        userAgent     : String,
        productId     : Int
    ) {
        self.userId         = userId
        self.userEmail      = userEmail
        self.userFullName   = userFullName
        self.clientId       = clientId
        self.eventTimestamp = eventTimestamp
        self.ipAddress      = ipAddress
        self.userAgent      = userAgent
        self.productId      = productId
    }
}
