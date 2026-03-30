public struct GradeChangeEvent: Encodable {
    public let courseId       : Int
    public let courseName     : String
    public let previousGrade  : Double
    public let newGrade       : Double
    public let maxGrade       : Double
    public let gradeItemName  : Int
    public let status         : GradeStatus

    public init(courseId: Int, courseName: String, previousGrade: Double, newGrade: Double, maxGrade: Double, gradeItemName: Int, status: GradeStatus) {
        self.courseId      = courseId
        self.courseName    = courseName
        self.previousGrade = previousGrade
        self.newGrade      = newGrade
        self.maxGrade      = maxGrade
        self.gradeItemName = gradeItemName
        self.status        = status
    }
}

public enum GradeStatus: String, Encodable {
    case success
    case fail
}
