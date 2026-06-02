// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BannerCoreKit",
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
            name: "BannerCoreKit"
        ),
        .testTarget(
            name: "BannerCoreKitTests",
            dependencies: ["BannerCoreKit"],
            path: "Tests"
        ),
    ]
)
