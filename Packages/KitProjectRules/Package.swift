// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KitProjectRules",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "KitProjectRules",
            targets: ["KitProjectRules"]
        ),
    ],
    dependencies: [
        .package(path: "../KitGitCore"),
    ],
    targets: [
        .target(
            name: "KitProjectRules",
            dependencies: [
                "KitGitCore",
            ],
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "KitProjectRulesTests",
            dependencies: ["KitProjectRules"],
            path: "Tests"
        ),
    ]
)
