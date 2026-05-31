// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginOpenXcode",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "PluginOpenXcode",
            targets: ["PluginOpenXcode"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKPluginKit"),
    ],
    targets: [
        .target(
            name: "PluginOpenXcode",
            dependencies: ["GitOKPluginKit"],
            path: "Sources/PluginOpenXcode",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "PluginOpenXcodeTests",
            dependencies: ["PluginOpenXcode"],
            path: "Tests"
        ),
    ]
)
