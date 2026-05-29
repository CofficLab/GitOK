// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginOpenRemote",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(name: "PluginOpenRemote", targets: ["PluginOpenRemote"]),
    ],
    dependencies: [
        .package(path: "../GitOKPluginKit"),
        .package(path: "../ProjectRulesKit"),
    ],
    targets: [
        .target(
            name: "PluginOpenRemote",
            dependencies: [
                "GitOKPluginKit",
                "ProjectRulesKit",
            ],
            path: "Sources/PluginOpenRemote",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginOpenRemoteTests",
            dependencies: ["PluginOpenRemote"],
            path: "Tests/PluginOpenRemoteTests"
        ),
    ]
)
