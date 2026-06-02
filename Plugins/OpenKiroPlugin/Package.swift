// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OpenKiroPlugin",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
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
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "OpenKiroPluginTests",
            dependencies: ["OpenKiroPlugin"],
            path: "Tests"
        ),
    ]
)
