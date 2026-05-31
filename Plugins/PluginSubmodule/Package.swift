// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginSubmodule",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "PluginSubmodule", targets: ["PluginSubmodule"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitCoreKit"),
        .package(path: "../../Packages/GitOKPluginKit"),
    ],
    targets: [
        .target(
            name: "PluginSubmodule",
            dependencies: [
                "GitCoreKit",
                "GitOKPluginKit",
            ],
            path: "Sources/PluginSubmodule",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginSubmoduleTests",
            dependencies: ["PluginSubmodule"],
            path: "Tests"
        ),
    ]
)
