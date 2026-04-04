public struct RegistrationEvent: Encodable {
    public let userId        : Int
    public let userEmail     : String
    public let userFullName  : String
    public let clientId      : String
    public let eventTimestamp: Int
    public let productId     : Int
    public let ipAddress     : String
    public let userAgent     : String
    public let phoneNumber   : String

    public init(
        userId        : Int,
        userEmail     : String,
        userFullName  : String,
        clientId      : String,
        eventTimestamp: Int,
        productId     : Int,
        ipAddress     : String,
        userAgent     : String,
        phoneNumber   : String
    ) {
        self.userId         = userId
        self.userEmail      = userEmail
        self.userFullName   = userFullName
        self.clientId       = clientId
        self.eventTimestamp = eventTimestamp
        self.productId      = productId
        self.ipAddress      = ipAddress
        self.userAgent      = userAgent
        self.phoneNumber    = phoneNumber
    }
}
