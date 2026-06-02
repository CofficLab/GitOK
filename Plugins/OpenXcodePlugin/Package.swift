// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OpenXcodePlugin",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "OpenXcodePlugin",
            targets: ["OpenXcodePlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "OpenXcodePlugin",
            dependencies: ["GitOKCoreKit"],
            path: "Sources",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "OpenXcodePluginTests",
            dependencies: ["OpenXcodePlugin"],
            path: "Tests"
        ),
    ]
)
