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
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "PluginSubmodule",
            dependencies: [
                "GitCoreKit",
                "GitOKCoreKit",
            ],
            path: "Sources",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginSubmoduleTests",
            dependencies: ["PluginSubmodule"],
            path: "Tests"
        ),
    ]
)
