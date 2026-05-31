// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginFileInfo",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "PluginFileInfo", targets: ["PluginFileInfo"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKPluginKit"),
    ],
    targets: [
        .target(
            name: "PluginFileInfo",
            dependencies: ["GitOKPluginKit"],
            path: "Sources/PluginFileInfo",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginFileInfoTests",
            dependencies: ["PluginFileInfo"],
            path: "Tests"
        ),
    ]
)
