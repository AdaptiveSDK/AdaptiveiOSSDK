public struct AdaptiveUser {
    public let userId      : String
    public let userEmail   : String
    public let userName    : String
    public let phoneNumber : String
    public let userGrade   : UserGrade?

    public init(
        userId: String,
        userEmail: String,
        userName: String,
        phoneNumber: String,
        userGrade: UserGrade? = nil
    ) {
        self.userId = userId
        self.userEmail = userEmail
        self.userName = userName
        self.phoneNumber = phoneNumber
        self.userGrade = userGrade
    }
}
