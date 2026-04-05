public struct LoginEvent: Encodable {
    public let userId       : Int
    public let userEmail    : String
    public let userFullName : String
    public let productId    : Int

    public init(
        userId      : Int,
        userEmail   : String,
        userFullName: String,
        productId   : Int
    ) {
        self.userId       = userId
        self.userEmail    = userEmail
        self.userFullName = userFullName
        self.productId    = productId
    }
}
