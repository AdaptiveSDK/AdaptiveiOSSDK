public struct BadgeEarnedEvent: Encodable {
    public let badgeId           : Int
    public let badgeName         : String
    public let badgeDescription  : String
    public let issuedBy          : String

    public init(badgeId: Int, badgeName: String, badgeDescription: String, issuedBy: String) {
        self.badgeId          = badgeId
        self.badgeName        = badgeName
        self.badgeDescription = badgeDescription
        self.issuedBy         = issuedBy
    }
}
