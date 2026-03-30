public struct CourseCompletionEvent: Encodable {
    public let courseId             : Int
    public let courseName           : String
    public let finalGrade           : Double
    public let completionTimestamp  : Int

    public init(courseId: Int, courseName: String, finalGrade: Double, completionTimestamp: Int) {
        self.courseId            = courseId
        self.courseName          = courseName
        self.finalGrade          = finalGrade
        self.completionTimestamp = completionTimestamp
    }
}
