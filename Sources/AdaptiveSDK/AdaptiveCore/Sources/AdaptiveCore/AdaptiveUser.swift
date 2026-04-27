public enum UserGrade: Int, Encodable {
    // Primary school (grades 1–6)
    case grade1Primary   = 1
    case grade2Primary   = 2
    case grade3Primary   = 3
    case grade4Primary   = 4
    case grade5Primary   = 5
    case grade6Primary   = 6
    // Preparatory school (grades 7–9)
    case grade1Prep      = 7
    case grade2Prep      = 8
    case grade3Prep      = 9
    // Secondary school (grades 10–12)
    case grade1Secondary = 10
    case grade2Secondary = 11
    case grade3Secondary = 12
}

public enum UserGender: Int, Encodable {
    case male   = 0
    case female = 1
}

public enum UserSchool: Int, Encodable {
    case governmentalArabicSchool = 1
    case experemintalSchool       = 2
    case privateArabicSchool      = 3
    case privateLanguageSchool    = 4
    case internationalSchool      = 5
}

public struct AdaptiveUser {
    public let userId      : String
    public let userEmail   : String
    public let userName    : String
    public let phoneNumber : String
    public let userGrade   : UserGrade?
    public let userGender  : UserGender?
    public let userSchool  : UserSchool?

    public init(
        userId: String,
        userEmail: String,
        userName: String,
        phoneNumber: String,
        userGrade: UserGrade? = nil,
        userGender: UserGender? = nil,
        userSchool: UserSchool? = nil
    ) {
        self.userId = userId
        self.userEmail = userEmail
        self.userName = userName
        self.phoneNumber = phoneNumber
        self.userGrade = userGrade
        self.userGender = userGender
        self.userSchool = userSchool
    }
}
