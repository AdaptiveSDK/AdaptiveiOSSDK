# Changelog

All notable changes to the Adaptive iOS SDK are documented here.  
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/). Versioning follows [Semantic Versioning](https://semver.org/).

## [1.0.32] – 2026-05-18

### Changed
- Unified version bump to `1.0.32` for all CocoaPods modules (`AdaptiveCore`, `AdaptiveAnalytics`, `AdaptiveMessaging`, `AdaptiveChat`, `AdaptiveSDK`) and SPM tag publishing.
- `AdaptiveChat` added to the `AdaptiveSDK` meta-pod and CocoaPods publish pipeline.

---

## [1.0.20] – 2026-04-18

### Changed
- Unified version bump to `1.0.20` for all CocoaPods modules (`AdaptiveCore`, `AdaptiveAnalytics`, `AdaptiveMessaging`, `AdaptiveSDK`) and SPM tag publishing.

---

## [1.0.24] – 2026-04-28
- Maintenance release and dependency updates.

## [1.0.23] – 2026-04-27

### Changed
- Unified version bump to `1.0.23` for all CocoaPods modules (`AdaptiveCore`, `AdaptiveAnalytics`, `AdaptiveMessaging`, `AdaptiveSDK`) and SPM tag publishing.

---

## [1.0.22] – 2026-04-19

### Changed
- Unified version bump to `1.0.22` for all CocoaPods modules (`AdaptiveCore`, `AdaptiveAnalytics`, `AdaptiveMessaging`, `AdaptiveSDK`) and SPM tag publishing.

---

## [1.0.21] – 2026-04-18

### Changed
- Unified version bump to `1.0.21` for all CocoaPods modules (`AdaptiveCore`, `AdaptiveAnalytics`, `AdaptiveMessaging`, `AdaptiveSDK`) and SPM tag publishing.

---

## [1.0.20] – 2026-04-18

### Changed
- Unified version bump to `1.0.20` for all CocoaPods modules (`AdaptiveCore`, `AdaptiveAnalytics`, `AdaptiveMessaging`, `AdaptiveSDK`) and SPM tag publishing.

---

## [1.0.19] – 2026-04-16

### Changed
- Unified version bump to `1.0.19` for all CocoaPods modules (`AdaptiveCore`, `AdaptiveAnalytics`, `AdaptiveMessaging`, `AdaptiveSDK`) and SPM tag publishing.

---

## [1.0.14] – 2026-04-15

### Changed
- Unified version bump to `1.0.14` for all CocoaPods modules (`AdaptiveCore`, `AdaptiveAnalytics`, `AdaptiveMessaging`, `AdaptiveSDK`) and SPM tag publishing.

---

## [1.0.12] – 2026-04-12

### Added
- **`AdaptiveUser.phoneNumber`** – new `String` field on the user model. Passed
  into `AdaptiveCore.login()` and automatically injected into every analytics
  event payload via `AnalyticsRepository.injectBaseFields()`.
- **`AdaptiveAnalytics` auto app-launch event** – instantiating `AdaptiveAnalytics`
  now fires an `app-launch` event asynchronously via a `Task`, ensuring the
  event is captured on every cold start without any additional developer
  integration.
- **Structured HTTP logging** – `InternalHttpClient` now emits a formatted
  `→ REQUEST` block (method, full URL, body) before every outgoing call and a
  `← RESPONSE` block (method, URL, HTTP status code, response body) on
  completion. All logs remain gated by the existing `AdaptiveLogger.debug` flag.

### Changed
- **`AdaptiveCore.login(userId:userName:userEmail:phoneNumber:)`** – extended
  with an optional `phoneNumber: String` parameter (defaults to `""`). Existing
  call sites without `phoneNumber` continue to compile unchanged.
- **`AdaptiveAnalytics.logUserPropertiesEvent(data: [String: Any])`** –
  signature changed from `UserPropertiesEvent` to a plain `[String: Any]`
  dictionary, letting each integration pass any custom user properties without
  being constrained to a fixed schema.
- **`AdaptiveMessaging.showNotification(from:)`** – notification `title` and
  `message` are now resolved from a nested `notification` dictionary inside the
  FCM data payload (`json["notification"]["title"]`) when present, falling back
  to the flat `json["title"]` / `json["description"]` fields. Both payload
  shapes are supported with no changes required by the consumer.

### Removed
- **`UserPropertiesEvent`** struct (`AdaptiveAnalytics`) – superseded by the
  dynamic `[String: Any]` parameter in `logUserPropertiesEvent()`. Migrate call
  sites by passing a plain dictionary: `["key": value, ...]`.

---

## [1.0.11] – 2026-04-08

### Changed
- **`Package.swift`** – lowered SPM iOS minimum deployment target from `.v15` to `.v12`.

---

## [1.0.10] – 2026-04-07

### Changed
- **All modules** – unified version bump to 1.0.10 to align `AdaptiveCore`, `AdaptiveAnalytics`, `AdaptiveMessaging`, and `AdaptiveSDK` on the same version.

---

## [1.0.9] – 2026-04-07

### Changed
- **`AdaptiveAnalytics`** – version bump to force CocoaPods CDN cache invalidation for consumers on older resolved versions.

---

## [1.0.8] – 2026-04-07

### Fixed
- **`AdaptiveCore`** – exposed `deviceId` as a `public` property so other modules can read the device identifier without depending on the `internal` `KeychainHelper`.
- **`AdaptiveMessaging`** – `MessagingRepository` now reads `AdaptiveCore.shared.deviceId` instead of calling `KeychainHelper` directly (cross-module visibility fix).
- **`AdaptiveMessaging`** – added missing `import AdaptiveCore` to `AdaptiveMessaging.swift`.
- **`AdaptiveMessaging`** – removed extraneous closing braces in `AdaptiveMessaging.swift`.
- **`AdaptiveAnalytics`** – corrected analytics event base path from `moodle/events/` to `events/`.

---

## [1.0.7] – 2026-04-07 _(superseded by 1.0.8)_

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
