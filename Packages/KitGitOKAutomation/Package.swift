// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KitGitOKAutomation",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "KitGitOKAutomation",
            targets: ["KitGitOKAutomation"]
        ),
    ],
    targets: [
        .target(
            name: "KitGitOKAutomation",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "KitGitOKAutomationTests",
            dependencies: ["KitGitOKAutomation"],
            path: "Tests"
        ),
    ]
)
