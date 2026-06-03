// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BannerCoreKit",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "BannerCoreKit",
            targets: ["BannerCoreKit"]
        ),
    ],
    targets: [
        .target(
            name: "BannerCoreKit",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "BannerCoreKitTests",
            dependencies: ["BannerCoreKit"],
            path: "Tests"
        ),
    ]
)
