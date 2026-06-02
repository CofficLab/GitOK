// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OpenTraePlugin",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(name: "OpenTraePlugin", targets: ["OpenTraePlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "OpenTraePlugin",
            dependencies: ["GitOKCoreKit"],
            path: "Sources",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "OpenTraePluginTests",
            dependencies: ["OpenTraePlugin"],
            path: "Tests"
        ),
    ]
)
