// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProjectSupportKit",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "ProjectSupportKit",
            targets: ["ProjectSupportKit"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ProjectSupportKit",
            dependencies: [],
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "ProjectSupportKitTests",
            dependencies: ["ProjectSupportKit"],
            path: "Tests"
        ),
    ]
)
