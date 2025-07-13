// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "IosVoiceControl",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "IosVoiceControl",
            targets: ["IosVoiceControl"]
        ),
    ],
    dependencies: [
        // Firebase iOS SDK
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0"),
        // InjectionIII for hot reloading (PRP validation infrastructure)
        .package(url: "https://github.com/krzysztofzablocki/Inject.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "IosVoiceControl",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "Inject", package: "Inject")
            ]
        ),
        .testTarget(
            name: "IosVoiceControlTests",
            dependencies: ["IosVoiceControl"]
        ),
    ]
)