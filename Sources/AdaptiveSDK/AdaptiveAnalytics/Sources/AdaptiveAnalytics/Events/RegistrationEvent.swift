public struct RegistrationEvent: Encodable {
    public let userId       : Int
    public let userEmail    : String
    public let userFullName : String
    public let productId    : Int
    public let phoneNumber  : String

    public init(
        userId      : Int,
        userEmail   : String,
        userFullName: String,
        productId   : Int,
        phoneNumber : String
    ) {
        self.userId       = userId
        self.userEmail    = userEmail
        self.userFullName = userFullName
        self.productId    = productId
        self.phoneNumber  = phoneNumber
    }
}
