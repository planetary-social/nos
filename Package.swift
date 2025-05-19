// swift-tools-version:5.9
import PackageDescription

let packageName = "Nos"
let package = Package(
    name: packageName,
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: packageName, targets: [packageName]),
        .library(name: "Logger", targets: ["Logger"]),
        .library(name: "NostrSDKWrapper", targets: ["NostrSDKWrapper"])
    ],
    dependencies: [
        // Required dependencies
        .package(url: "https://github.com/tesseract-one/BIP39.swift.git", from: "0.2.0"),
        .package(url: "https://github.com/krzysztofzablocki/Inject.git", from: "1.0.5"),
        .package(url: "https://github.com/daltoniam/Starscream.git", from: "4.0.4"),
        .package(url: "https://github.com/getsentry/sentry-cocoa.git", from: "8.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.4.2"),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.5.3"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.0.4"),
        .package(url: "https://github.com/SDWebImage/SDWebImageSwiftUI.git", from: "2.2.3"),
        .package(url: "https://github.com/SDWebImage/SDWebImageWebPCoder.git", from: "0.12.0"),
        .package(url: "https://github.com/posthog/posthog-ios.git", from: "2.0.0"),
        .package(url: "https://github.com/pointfreeco/swiftui-navigation", from: "1.0.2")
    ],
    targets: [
        .target(
            name: packageName,
            dependencies: [
                "Logger",
                "NostrSDKWrapper", // Use our wrapper for NostrSDK functionality
                .product(name: "BIP39", package: "BIP39.swift"),
                .product(name: "Inject", package: "Inject"),
                .product(name: "Starscream", package: "Starscream"),
                .product(name: "Sentry", package: "sentry-cocoa"),
                .product(name: "SentrySwiftUI", package: "sentry-cocoa"),
                .product(name: "SwiftSoup", package: "SwiftSoup"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "DequeModule", package: "swift-collections"),
                .product(name: "SDWebImageSwiftUI", package: "SDWebImageSwiftUI"),
                .product(name: "SDWebImageWebPCoder", package: "SDWebImageWebPCoder"),
                .product(name: "PostHog", package: "posthog-ios"),
                .product(name: "SwiftUINavigation", package: "swiftui-navigation"),
            ],
            path: packageName
        ),
        .target(
            name: "Logger",
            dependencies: [
                .product(name: "Logging", package: "swift-log")
            ],
            path: "Sources/Logger"
        ),
        // Create a wrapper for NostrSDK and CashuSwift functionality
        // This avoids direct dependencies that might conflict
        .target(
            name: "NostrSDKWrapper",
            dependencies: [],
            path: "Sources/NostrSDKWrapper",
            resources: [
                .copy("Resources")
            ]
        )
    ]
)