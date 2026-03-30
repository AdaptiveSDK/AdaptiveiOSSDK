public struct QuizSubmissionEvent: Encodable {
    public let courseId          : Int
    public let courseName        : String
    public let quizId            : Int
    public let quizName          : String
    public let grade             : Double
    public let maxGrade          : Double
    public let attemptNumber     : Int
    public let timeTakenSeconds  : Int

    public init(courseId: Int, courseName: String, quizId: Int, quizName: String, grade: Double, maxGrade: Double, attemptNumber: Int, timeTakenSeconds: Int) {
        self.courseId         = courseId
        self.courseName       = courseName
        self.quizId           = quizId
        self.quizName         = quizName
        self.grade            = grade
        self.maxGrade         = maxGrade
        self.attemptNumber    = attemptNumber
        self.timeTakenSeconds = timeTakenSeconds
    }
}
