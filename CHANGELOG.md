# Changelog

All notable changes to the Adaptive iOS SDK are documented here.  
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/). Versioning follows [Semantic Versioning](https://semver.org/).

---

## [1.0.6] – 2026-04-07

### Added
- **`AdaptiveMessaging.sendEvent(eventName:data:)`** – send arbitrary messaging events. Events are posted immediately when the user is logged in, or automatically queued and flushed (one by one, in order) on the next `AdaptiveCore.login()` call.
- **`PendingEvent`** – internal `Codable` struct persisted in `UserDefaults` to store events that arrive before login.
- **`MessagingPreferences`** – extended with `addPendingEvent(_:)`, `getPendingEvents()`, and `clearPendingEvents()` to manage the pre-login event queue.
- **`MessagingRepository.sendEvent(eventName:body:userId:)`** – posts event payloads to `/events/{eventName}` with `userId` and `deviceId` injected.

### Changed
- **`AdaptiveMessaging` login listener** – now sequentially flushes both the pending push token **and** all pending events after `AdaptiveCore.login()` is called (token first, then events one by one).

---

## [1.0.3] – 2026-04-04

### Added
- **`RegistrationEvent`** – tracks new user registrations (`POST moodle/events/registration`).
- **`LoginEvent`** – tracks user login sessions (`POST moodle/events/login`).
- **`UserPropertiesEvent`** – tracks user profile metadata with snake_case JSON keys: `year_id`, `fcm_token`, `user_type`, `school_lang_type`, `registration_date`, `parent_id` (`POST moodle/events/user-properties`).
- Corresponding `logRegistrationEvent()`, `logLoginEvent()`, and `logUserPropertiesEvent()` methods on `AdaptiveAnalytics`.
- `Secrets.swift.template` – copy to `Secrets.swift` (gitignored) and fill in credentials. Never committed.

### Changed
- **`InternalHttpClient`** – overhauled request failure handling:
  - On initial failure, checks connection before each of up to **3 inline retries** with linear back-off (1 s, 2 s).
  - If connection drops at any retry attempt, request is immediately moved to the **persistent Keychain queue** instead of retrying blindly.
  - `get()` now also checks connectivity on entry and applies the same retry logic.
  - `QueueProcessor` continues to drain queued requests with exponential back-off once connectivity is restored.
- **Secret hygiene** – Azure Function Key removed from source code. It now lives in `Secrets.swift` (gitignored). `Secrets.swift.template` is committed as a reference.

---

## [1.0.2] – 2026-03-15

### Added
- `AdaptiveMessaging` made fully public; added `showNotification(from:)`.

---

## [1.0.1] – 2026-03-10

### Fixed
- Podspec GitHub URLs corrected.

---

## [1.0.0] – 2026-03-01

### Added
- Initial release of the Adaptive iOS SDK.
- `AdaptiveCore` – networking, persistent Keychain queue, network observer.
- `AdaptiveAnalytics` – events: `GradeChangeEvent`, `StudentInactivityEvent`, `ModuleCompletionEvent`, `BadgeEarnedEvent`, `CourseEnrollmentEvent`, `CourseCompletionEvent`, `AssignmentSubmissionEvent`, `QuizSubmissionEvent`.
- `AdaptiveMessaging` – push-messaging support.
- Swift Package Manager and CocoaPods support.
