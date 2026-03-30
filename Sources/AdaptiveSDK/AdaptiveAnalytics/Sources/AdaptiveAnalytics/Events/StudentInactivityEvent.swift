
public struct StudentInactivityEvent: Encodable {
    public let lastLoginTimestamp    : Int
    public let inactiveDays          : Int
    public let lastAccessedCourseId  : Int

    public init(lastLoginTimestamp: Int, inactiveDays: Int, lastAccessedCourseId: Int) {
        self.lastLoginTimestamp   = lastLoginTimestamp
        self.inactiveDays         = inactiveDays
        self.lastAccessedCourseId = lastAccessedCourseId
    }
}
