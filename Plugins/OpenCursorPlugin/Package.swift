// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OpenCursorPlugin",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "OpenCursorPlugin",
            targets: ["OpenCursorPlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "OpenCursorPlugin",
            dependencies: ["GitOKCoreKit"],
            path: "Sources",
            resources: [
                .process("Localizable.xcstrings"),
            ]
        ),
        .testTarget(
            name: "OpenCursorPluginTests",
            dependencies: ["OpenCursorPlugin"],
            path: "Tests"
        ),
    ]
)
