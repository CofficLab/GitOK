// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginOpenFinder",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "PluginOpenFinder",
            targets: ["PluginOpenFinder"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "PluginOpenFinder",
            dependencies: ["GitOKCoreKit"],
            path: "Sources/PluginOpenFinder",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "PluginOpenFinderTests",
            dependencies: ["PluginOpenFinder"],
            path: "Tests"
        ),
    ]
)
