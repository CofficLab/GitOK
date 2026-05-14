// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GitCoreKit",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "GitCoreKit",
            targets: ["GitCoreKit"]
        ),
    ],
    targets: [
        .target(
            name: "GitCoreKit"
        ),
        .testTarget(
            name: "GitCoreKitTests",
            dependencies: ["GitCoreKit"]
        ),
    ]
)
