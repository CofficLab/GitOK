// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GitOKAutomationKit",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "GitOKAutomationKit",
            targets: ["GitOKAutomationKit"]
        ),
    ],
    targets: [
        .target(
            name: "GitOKAutomationKit"
        ),
        .testTarget(
            name: "GitOKAutomationKitTests",
            dependencies: ["GitOKAutomationKit"]
        ),
    ]
)
