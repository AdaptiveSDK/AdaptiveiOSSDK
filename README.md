# Adaptive iOS SDK

The Adaptive iOS SDK enables seamless integration with the Adaptive Learning platform. It is split into focused modules that you can include independently based on your needs.

| Module | Description |
|---|---|
| `AdaptiveCore` | Required base module — handles initialization, user session, networking & offline queue |
| `AdaptiveAnalytics` | Tracks learning events (grades, quizzes, assignments, etc.) |
| `AdaptiveMessaging` | Handles FCM push notifications from the Adaptive platform |

---

## Requirements

- **iOS:** 15.0+
- **macOS:** 12.0+
- **Swift:** 5.9+
- **Xcode:** 15+

---

## Installation

### Swift Package Manager

Add the dependency in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/adaptive/AdaptiveSDK.git", from: "1.0.0")
]
```

Then add the products you need to your target:

```swift
.target(
    name: "MyApp",
    dependencies: [
        .product(name: "AdaptiveCore",      package: "AdaptiveSDK"),
        .product(name: "AdaptiveAnalytics", package: "AdaptiveSDK"),
        .product(name: "AdaptiveMessaging", package: "AdaptiveSDK"),
    ]
)
```

Or via **Xcode**: File → Add Package Dependencies → paste the repo URL.

### CocoaPods

Add to your `Podfile`:

```ruby
# All modules
pod 'AdaptiveSDK'

# Or pick only what you need
pod 'AdaptiveCore'
pod 'AdaptiveAnalytics'
pod 'AdaptiveMessaging'
```

Then run:

```bash
pod install
```

---

## Step 1 — Initialize the SDK

Call `AdaptiveCore.shared.initialize()` once, as early as possible — in `AppDelegate` or your `@main` App struct.

```swift
import AdaptiveCore

AdaptiveCore.shared.initialize(
    clientId: "YOUR_CLIENT_ID",
    debug:    true   // set to false in production
)
```

| Parameter | Type | Description |
|---|---|---|
| `clientId` | `String` | Your Adaptive platform client ID |
| `debug` | `Bool` | Enables verbose logging (default: `false`) |

---

## Step 2 — Set the Current User

After a successful login in your app, identify the user to the SDK:

```swift
AdaptiveCore.shared.login(
    userId:    "user_123",
    userName:  "Jane Doe",
    userEmail: "jane@example.com"
)
```

> **Important:** You must call `login()` before using `AdaptiveAnalytics` or `AdaptiveMessaging`.

To clear the session (e.g. on logout):

```swift
AdaptiveCore.shared.logout()
```

---

## Step 3 — Analytics (optional)

Import and use `AdaptiveAnalytics` to log learning events. All methods are `async` — call them from a `Task` or an `async` context.

```swift
import AdaptiveAnalytics

let analytics = AdaptiveAnalytics()
```

### Course Enrollment

```swift
await analytics.logCourseEnrollmentEvent(data: CourseEnrollmentEvent(
    courseId:         101,
    courseName:       "Introduction to Swift",
    enrollmentMethod: .manualEnrollment,
    roleName:         "student"
))
```

### Grade Change

```swift
await analytics.logGradeChangeEvent(data: GradeChangeEvent(
    courseId:      101,
    courseName:    "Introduction to Swift",
    previousGrade: 70.0,
    newGrade:      85.0,
    maxGrade:      100.0,
    gradeItemName: 1,
    status:        .success
))
```

### Quiz Submission

```swift
await analytics.logQuizSubmissionEvent(data: QuizSubmissionEvent(
    courseId:         101,
    courseName:       "Introduction to Swift",
    quizId:           55,
    quizName:         "Midterm Quiz",
    grade:            90.0,
    maxGrade:         100.0,
    attemptNumber:    1,
    timeTakenSeconds: 1200
))
```

### Assignment Submission

```swift
await analytics.logAssignmentSubmissionEvent(data: AssignmentSubmissionEvent(
    courseId:           101,
    courseName:         "Introduction to Swift",
    assignmentId:       30,
    assignmentName:     "Final Project",
    isLate:             false,
    attemptNumber:      1,
    dueDateTimestamp:   1711670400,
    submissionStatus:   .submitted
))
```

### Module Completion

```swift
await analytics.logModuleCompletionEvent(data: ModuleCompletionEvent(
    courseId:        101,
    moduleId:        12,
    courseName:      "Introduction to Swift",
    moduleName:      "Concurrency Deep Dive",
    completionState: .completePass
))
```

### Badge Earned

```swift
await analytics.logBadgeEarnedEvent(data: BadgeEarnedEvent(
    badgeId:          7,
    badgeName:        "Top Performer",
    badgeDescription: "Awarded for scoring above 90% in all quizzes",
    issuedBy:         "System"
))
```

### Student Inactivity

```swift
await analytics.logStudentInactivityEvent(data: StudentInactivityEvent(
    lastLoginTimestamp:   1711670400,
    inactiveDays:         7,
    lastAccessedCourseId: 101
))
```

---

## Step 4 — Push Notifications / Messaging (iOS only, optional)

### 4.1 — Request notification permission

Request permission at an appropriate point in your app (e.g. after login):

```swift
import UserNotifications

UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
    print("Notification permission granted: \(granted)")
}
```

### 4.2 — Register the FCM Token

After obtaining the FCM token, pass it to the SDK:

```swift
import AdaptiveMessaging

await AdaptiveMessaging.shared.updateFCMToken(token: fcmToken)
```

### 4.3 — Handle Incoming Notifications

In your notification delegate or messaging handler, use the SDK helpers to detect and display Adaptive notifications:

```swift
import AdaptiveMessaging

// Check if a notification payload is from Adaptive
if AdaptiveMessaging.shared.isAdaptiveNotification(data: payloadString) {
    AdaptiveMessaging.shared.showNotitication()
}
```

The payload JSON must contain a `"source": "adaptive"` field for `isAdaptiveNotification()` to return `true`.

---

## Offline Support

`AdaptiveCore` includes a persistent request queue backed by the Keychain. If a network request fails or the device is offline, the request is saved locally and automatically retried with exponential backoff once connectivity is restored. No additional configuration is needed.

---

## Module Overview

```
AdaptiveSDK
├── AdaptiveCore        ← AdaptiveCore, AdaptiveUser, networking, offline queue
├── AdaptiveAnalytics   ← AdaptiveAnalytics + all event structs
└── AdaptiveMessaging   ← AdaptiveMessaging, FCM token sync, notification display (iOS only)
```

---

## Troubleshooting

| Issue | Solution |
|---|---|
| App crashes with "You Must call AdaptiveCore.initialize() first" | Call `AdaptiveCore.shared.initialize()` before any other SDK call |
| Events not sent | Ensure `AdaptiveCore.shared.login()` was called before logging events |
| Notifications not appearing | Ensure notification permission is granted via `UNUserNotificationCenter` |
| Debugging network calls | Enable `debug: true` in `initialize()` and check the console for `[Adaptive]` tags |

---

## 🐛 Found a Bug? Contact Us

If you encounter a bug or have a question, please open an issue or reach out directly:

👉 **[https://github.com/AdaptiveSDK/AdaptiveSDK](https://github.com/AdaptiveSDK/AdaptiveSDK)**
