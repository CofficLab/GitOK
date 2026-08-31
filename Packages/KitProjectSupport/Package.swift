// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KitProjectSupport",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "KitProjectSupport",
            targets: ["KitProjectSupport"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "KitProjectSupport",
            dependencies: [],
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "KitProjectSupportTests",
            dependencies: ["KitProjectSupport"],
            path: "Tests"
        ),
    ]
)
