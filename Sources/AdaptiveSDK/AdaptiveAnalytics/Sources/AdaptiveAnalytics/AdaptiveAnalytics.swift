#if os(iOS)
import Foundation
import AdaptiveCore

public final class AdaptiveAnalytics {
    nonisolated(unsafe) public static let shared = AdaptiveAnalytics()

    // ── Store-and-forward (pre-login event queue) ────────────────────────────────────────
    //
    // Analytics events may be fired before the user has logged in (e.g.
    // registration events). Instead of silently dropping them we persist
    // them locally and flush them once AdaptiveCore.shared.login() is called.
    //
    // The loginListener is registered once in init and lives for the lifetime
    // of the singleton.
    //
    // On login the listener:
    //   1. Flushes any pre-login pending events in queue order.
    //   2. After a registration event is confirmed, calls postDeviceToken so
    //      the backend can associate this device with the newly registered user.
    // ───────────────────────────────────────────────────────────────────────────

    private let repo = AnalyticsRepository()

    /// Eagerly initializes the Analytics module so that its login listener is
    /// registered with `AdaptiveCore` **before** any `login()` call happens.
    ///
    /// Call this once during app startup (e.g. from your Flutter plugin or
    /// AppDelegate.didFinishLaunching). Idempotent.
    ///
    /// Without this, `app-launch` will not fire for returning users who only
    /// call `AdaptiveCore.shared.login(...)` and never invoke an analytics
    /// method.
    public static func initialize() {
        _ = shared // triggers init()
        AdaptiveLogger.log(tag: "Analytics", message: "Analytics module initialized")
    }

    private init() {
        AdaptiveCore.shared.addLoginListener { [weak self] user in
            guard let self = self else { return }
            Task {
                // 1. Fire app-launch immediately after login
                await self.logAppLaunchEvent()

                // 2. Flush any pre-login pending events (in order)
                let pendingEvents = AnalyticsPreferences.getPendingEvents()
                if !pendingEvents.isEmpty {
                    AdaptiveLogger.log(
                        tag: "Analytics",
                        message: "Login detected -- flushing \(pendingEvents.count) pending event(s) for user \(user.userId)"
                    )
                    AnalyticsPreferences.clearPendingEvents()
                    for event in pendingEvents {
                        guard let data = event.body.data(using: .utf8) else { continue }
                        do {
                            try await self.repo.post(path: "events/\(event.queryName)", data: data)
                            AdaptiveLogger.log(tag: "Analytics", message: "Pending event '\(event.queryName)' sent successfully")

                            // After a registration event is flushed, notify
                            // listeners (e.g. Messaging) so they can react
                            // (e.g. post the FCM token for the new user).
                            if event.queryName == "registration" {
                                AdaptiveCore.shared.notifyRegistration(user)
                            }
                        } catch {
                            AdaptiveLogger.log(tag: "Analytics", message: "Pending event '\(event.queryName)' failed: \(error)")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Public Event Methods

    /// Tracks a new user registration and – as a best practice – automatically
    /// sends the device FCM token to `/device-tokens` right after the
    /// registration event is accepted by the server.
    ///
    /// **FCM token resolution:**
    /// The token is read from `AdaptiveCore.shared.getLatestFcmToken()`, which
    /// is written by `AdaptiveMessaging.updateFCMToken(_:)`. This survives app
    /// restarts and is available even when the token arrived before the user
    /// registered. If no token has been stored yet the device-token step is
    /// skipped silently.
    ///
    /// **Pre-login (deferred) path:** when there is no authenticated user the
    /// registration event is queued as usual. The login-flush listener calls
    /// `postDeviceToken` immediately after the registration entry is confirmed.
    public func logRegistrationEvent(data: RegistrationEvent) async {
        AdaptiveCore.shared.checkInitialization()

        guard let currentUser = AdaptiveCore.shared.currentUser else {
            // Deferred path: queue the event and wait for login.
            // The login-flush listener will call postDeviceTokenAfterRegistration
            // right after this event is confirmed.
            guard let body = String(data: (try? JSONEncoder().encode(data)) ?? Data(), encoding: .utf8) else { return }
            AnalyticsPreferences.addPendingEvent(PendingAnalyticsEvent(queryName: "registration", body: body))
            AdaptiveLogger.log(
                tag: "Analytics",
                message: "Registration Event queued -- will be sent when AdaptiveCore.shared.login() is called"
            )
            return
        }

        // Immediate path: user is already authenticated (e.g. re-registration).
        // Send registration first, then device-token in sequence.
        guard let regData = try? JSONEncoder().encode(data),
              let regBody = String(data: regData, encoding: .utf8) else { return }
        do {
            guard let bodyData = regBody.data(using: .utf8) else { return }
            try await repo.post(path: "events/registration", data: bodyData)
            AdaptiveLogger.log(tag: "Analytics", message: "Registration Event sent successfully")
            AdaptiveCore.shared.notifyRegistration(currentUser)
        } catch {
            AdaptiveLogger.log(tag: "Analytics", message: "Registration Event Error: \(error)")
        }
    }

    public func logLoginEvent(data: LoginEvent) async {
        await logEvent(queryName: "login", event: data, eventName: "Login Event")
    }

    public func setUserProperties(data: [String: Any]) async {
        let wrapped: [String: Any] = ["json": data]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: wrapped),
              let body = String(data: jsonData, encoding: .utf8) else { return }
        await logEventRaw(queryName: "set-user-info", body: body, eventName: "Set User Info Event")
    }

    public func logCustomEvent(eventName: String, data: [String: Any]) async {
        let wrapped: [String: Any] = ["EventPayloadJson": data , "EventName" : eventName]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: wrapped),
              let body = String(data: jsonData, encoding: .utf8) else { return }
        await logEventRaw(queryName: "custom", body: body, eventName: "\(eventName) Event")
    }

    public func logGradeChangeEvent(data: GradeChangeEvent) async {
        await logEvent(queryName: "grade-change", event: data, eventName: "Grade Change Event")
    }

    public func logStudentInactivityEvent(data: StudentInactivityEvent) async {
        await logEvent(queryName: "inactivity", event: data, eventName: "Student Inactivity Event")
    }

    public func logModuleCompletionEvent(data: ModuleCompletionEvent) async {
        await logEvent(queryName: "module-completion", event: data, eventName: "Module Completion Event")
    }

    public func logAppLaunchEvent() async {
        await logEventRaw(queryName: "app-launch", body: "{}", eventName: "App Launch Event")
    }

    public func logBadgeEarnedEvent(data: BadgeEarnedEvent) async {
        await logEvent(queryName: "badge-earned", event: data, eventName: "Badge Earned Event")
    }

    public func logCourseEnrollmentEvent(data: CourseEnrollmentEvent) async {
        await logEvent(queryName: "course-enrollment", event: data, eventName: "Course Enrollment Event")
    }

    public func logCourseCompletionEvent(data: CourseCompletionEvent) async {
        await logEvent(queryName: "course-completion", event: data, eventName: "Course Completion Event")
    }

    public func logAssignmentSubmissionEvent(data: AssignmentSubmissionEvent) async {
        await logEvent(queryName: "assignment-submission", event: data, eventName: "Assignment Submission Event")
    }

    public func logQuizSubmissionEvent(data: QuizSubmissionEvent) async {
        await logEvent(queryName: "quiz-submission", event: data, eventName: "Quiz Submission Event")
    }

    // MARK: - Private Helpers

    /// Generic helper: encodes an `Encodable` event then delegates to `logEventRaw`.
    private func logEvent<T: Encodable>(queryName: String, event: T, eventName: String) async {
        guard let data = try? JSONEncoder().encode(event),
              let body = String(data: data, encoding: .utf8) else { return }
        await logEventRaw(queryName: queryName, body: body, eventName: eventName)
    }

    /// Core dispatch: sends immediately if a user is logged in, otherwise queues for later.
    private func logEventRaw(queryName: String, body: String, eventName: String) async {
        AdaptiveCore.shared.checkInitialization()

        guard AdaptiveCore.shared.currentUser != nil else {
            // Deferred path: persist the event and wait for login.
            AnalyticsPreferences.addPendingEvent(PendingAnalyticsEvent(queryName: queryName, body: body))
            AdaptiveLogger.log(
                tag: "Analytics",
                message: "\(eventName) queued -- will be sent when AdaptiveCore.shared.login() is called"
            )
            return
        }

        // Fast path: user is authenticated, send straight away.
        guard let data = body.data(using: .utf8) else { return }
        do {
            try await repo.post(path: "events/\(queryName)", data: data)
        } catch {
            AdaptiveLogger.log(tag: "Analytics", message: "\(eventName) Error: \(error)")
        }
    }
}
#endif
