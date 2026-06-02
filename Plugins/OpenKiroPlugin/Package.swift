// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OpenKiroPlugin",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "OpenKiroPlugin", targets: ["OpenKiroPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "OpenKiroPlugin",
            dependencies: ["GitOKCoreKit"],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "OpenKiroPluginTests",
            dependencies: ["OpenKiroPlugin"],
            path: "Tests"
        ),
    ]
)
