// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginThemeStatusBar",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "PluginThemeStatusBar", targets: ["PluginThemeStatusBar"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "PluginThemeStatusBar",
            dependencies: [
                "GitOKCoreKit",
            ],
            path: "Sources",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginThemeStatusBarTests",
            dependencies: ["PluginThemeStatusBar"],
            path: "Tests"
        ),
    ]
)
