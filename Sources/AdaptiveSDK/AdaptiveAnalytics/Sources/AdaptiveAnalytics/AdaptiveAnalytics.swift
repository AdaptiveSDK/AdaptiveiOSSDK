import Foundation
import AdaptiveCore

public final class AdaptiveAnalytics {

    private let repo = AnalyticsRepository()

    public init() {}

    
    public func logGradeChangeEvent (data : GradeChangeEvent)  async{
        await logEvent(path: "grade-change", data: data)
    }

    public func logStudentInactivityEvent(data: StudentInactivityEvent) async {
        await  logEvent(path:"inactivity",data:data);
    }

    public func logModuleCompletionEvent(data: ModuleCompletionEvent)async {
        await logEvent(path:"module-completion",data:data);
    }

    public func logBadgeEarnedEvent(data: BadgeEarnedEvent)async{
        await logEvent(path:"badge-earned",data:data);

    }

    public func logCourseEnrollmentEvent(data: CourseEnrollmentEvent) async {
        await logEvent(path: "course-enrollment", data: data)
    }

    public func logCourseCompletionEvent(data: CourseCompletionEvent) async {
        await logEvent(path: "course-completion", data: data)
    }

    public func logAssignmentSubmissionEvent(data: AssignmentSubmissionEvent)async{
        await logEvent(path:"assignment-submission",data:data);
    }

    public func logQuizSubmissionEvent(data: QuizSubmissionEvent)async{
        await logEvent(path:"quiz-submission",data:data);
    }
    
    private func logEvent(path: String, data: Encodable) async {
        AdaptiveCore.shared.checkInitialization()
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        try? await repo.post(path: "moodle/events/\(path)", data: encoded)
    }
}
