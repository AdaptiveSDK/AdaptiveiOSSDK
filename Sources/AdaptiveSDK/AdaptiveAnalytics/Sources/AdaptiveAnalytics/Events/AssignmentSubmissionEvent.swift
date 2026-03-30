public struct AssignmentSubmissionEvent: Encodable {
    public let courseId           : Int
    public let courseName         : String
    public let assignmentId       : Int
    public let assignmentName     : String
    public let isLate             : Bool
    public let attemptNumber      : Int
    public let dueDateTimestamp   : Int
    public let submissionStatus   : SubmissionStatus

    public init(courseId: Int, courseName: String, assignmentId: Int, assignmentName: String, isLate: Bool, attemptNumber: Int, dueDateTimestamp: Int, submissionStatus: SubmissionStatus) {
        self.courseId         = courseId
        self.courseName       = courseName
        self.assignmentId     = assignmentId
        self.assignmentName   = assignmentName
        self.isLate           = isLate
        self.attemptNumber    = attemptNumber
        self.dueDateTimestamp = dueDateTimestamp
        self.submissionStatus = submissionStatus
    }
}

public enum SubmissionStatus: String, Encodable {
    case submitted
    case draft
    case reopened
}
