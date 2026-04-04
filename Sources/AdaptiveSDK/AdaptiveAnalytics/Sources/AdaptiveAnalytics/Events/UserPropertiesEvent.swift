public struct UserPropertiesEvent: Encodable {
    public let yearId           : Int
    public let fcmToken         : String
    public let userType         : String
    public let schoolLangType   : String
    public let registrationDate : Int
    public let parentId         : Int

    enum CodingKeys: String, CodingKey {
        case yearId           = "year_id"
        case fcmToken         = "fcm_token"
        case userType         = "user_type"
        case schoolLangType   = "school_lang_type"
        case registrationDate = "registration_date"
        case parentId         = "parent_id"
    }

    public init(
        yearId          : Int,
        fcmToken        : String,
        userType        : String,
        schoolLangType  : String,
        registrationDate: Int,
        parentId        : Int
    ) {
        self.yearId           = yearId
        self.fcmToken         = fcmToken
        self.userType         = userType
        self.schoolLangType   = schoolLangType
        self.registrationDate = registrationDate
        self.parentId         = parentId
    }
}
