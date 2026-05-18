// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AdaptiveSDK",
    platforms: [
        .iOS(.v12),
    ],
    products: [
        .library(name: "AdaptiveCore",      targets: ["AdaptiveCore"]),
        .library(name: "AdaptiveAnalytics", targets: ["AdaptiveAnalytics"]),
        .library(name: "AdaptiveMessaging", targets: ["AdaptiveMessaging"]),
        .library(name: "AdaptiveChat",      targets: ["AdaptiveChat"]),
    ],
    targets: [
        // MARK: - AdaptiveCore
        .target(
            name: "AdaptiveCore",
            path: "Sources/AdaptiveSDK/AdaptiveCore/Sources/AdaptiveCore"
        ),

        // MARK: - AdaptiveAnalytics
        .target(
            name: "AdaptiveAnalytics",
            dependencies: ["AdaptiveCore"],
            path: "Sources/AdaptiveSDK/AdaptiveAnalytics/Sources/AdaptiveAnalytics"
        ),

        // MARK: - AdaptiveMessaging
        .target(
            name: "AdaptiveMessaging",
            dependencies: ["AdaptiveCore"],
            path: "Sources/AdaptiveSDK/AdaptiveMessaging/Sources/AdaptiveMessaging"
        ),

        // MARK: - AdaptiveChat
        .target(
            name: "AdaptiveChat",
            dependencies: ["AdaptiveCore"],
            path: "Sources/AdaptiveSDK/AdaptiveChat/Sources/AdaptiveChat"
        ),
    ],
    swiftLanguageVersions: [.v5]
)
