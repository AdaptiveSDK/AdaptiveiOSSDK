public struct LoginEvent: Encodable {
    public let userId       : Int
    public let loginMethod    : LoginMethod

    public init(
        userId      : Int,
        loginMethod   : LoginMethod
    ) {
        self.userId       = userId
        self.loginMethod    = loginMethod
    }
}


public enum LoginMethod: Int, Encodable {
    case emailAndPassword    = 0
    case google      = 1
    case facebook  = 2
    case apple  = 3
    case x  = 4
    case phoneAndPassword  = 5
}
