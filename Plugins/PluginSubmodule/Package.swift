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
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "PluginSubmodule",
            dependencies: [
                                "GitOKCoreKit",
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
