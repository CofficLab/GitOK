// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GitOKAutomationKit",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "GitOKAutomationKit",
            targets: ["GitOKAutomationKit"]
        ),
    ],
    targets: [
        .target(
            name: "GitOKAutomationKit",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "GitOKAutomationKitTests",
            dependencies: ["GitOKAutomationKit"],
            path: "Tests"
        ),
    ]
)
