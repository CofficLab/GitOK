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
        .package(path: "../../Packages/GitOKUI"),
    ],
    targets: [
        .target(
            name: "PluginThemeStatusBar",
            dependencies: [
                "GitOKCoreKit",
                "GitOKUI",
            ],
            path: "Sources/PluginThemeStatusBar",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginThemeStatusBarTests",
            dependencies: ["PluginThemeStatusBar"],
            path: "Tests"
        ),
    ]
)
