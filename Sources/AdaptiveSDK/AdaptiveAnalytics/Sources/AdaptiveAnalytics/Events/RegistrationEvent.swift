public struct RegistrationEvent: Encodable {
    public let userId       : Int
    public let userType    : UserType
    public let userName : String
    public let registrationMethod    : LoginMethod
    public let userMobile  : String

    public init(
        userId      : Int,
        userType    : UserType,
        userName: String,
        registrationMethod   : LoginMethod,
        userMobile : String
    ) {
        self.userId       = userId
        self.userType    = userType
        self.userName = userName
        self.registrationMethod    = registrationMethod
        self.userMobile  = userMobile
    }
}


public enum UserType: Int, Encodable {
    case student    = 0
    case teacher      = 1
    case parent  = 2
}
