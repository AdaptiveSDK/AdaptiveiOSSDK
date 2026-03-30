public struct ModuleCompletionEvent: Encodable {
    public let courseId         : Int
    public let moduleId         : Int
    public let courseName       : String
    public let moduleName       : String
    public let completionState  : ModuleCompletionState

    public init(courseId: Int, moduleId: Int, courseName: String, moduleName: String, completionState: ModuleCompletionState) {
        self.courseId        = courseId
        self.moduleId        = moduleId
        self.courseName      = courseName
        self.moduleName      = moduleName
        self.completionState = completionState
    }
}

public enum ModuleCompletionState: Int, Encodable {
    case incomplete    = 0
    case complete      = 1
    case completePass  = 2
    case completeFail  = 3
}
