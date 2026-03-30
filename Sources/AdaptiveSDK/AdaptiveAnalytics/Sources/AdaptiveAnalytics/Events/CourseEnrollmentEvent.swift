
public struct CourseEnrollmentEvent: Encodable {
    public let courseId          : Int
    public let courseName        : String
    public let enrollmentMethod  : EnrollmentMethod
    public let roleName          : String

    public init(courseId: Int, courseName: String, enrollmentMethod: EnrollmentMethod, roleName: String) {
        self.courseId         = courseId
        self.courseName       = courseName
        self.enrollmentMethod = enrollmentMethod
        self.roleName         = roleName
    }
}

public enum EnrollmentMethod: Int, Encodable {
    case selfEnrollment   = 0
    case manualEnrollment = 1
}

