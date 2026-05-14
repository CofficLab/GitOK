// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProjectSupportKit",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "ProjectSupportKit",
            targets: ["ProjectSupportKit"]
        ),
    ],
    dependencies: [
        .package(path: "../GitCoreKit"),
    ],
    targets: [
        .target(
            name: "ProjectSupportKit",
            dependencies: ["GitCoreKit"]
        ),
        .testTarget(
            name: "ProjectSupportKitTests",
            dependencies: ["ProjectSupportKit"]
        ),
    ]
)
