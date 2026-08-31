// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginThemeStatusBar",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PluginThemeStatusBar", targets: ["ThemeStatusBarPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/KitGitOKCore"),
    ],
    targets: [
        .target(
            name: "ThemeStatusBarPlugin",
            dependencies: [
                "KitGitOKCore",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "ThemeStatusBarPluginTests",
            dependencies: ["ThemeStatusBarPlugin"],
            path: "Tests"
        ),
    ]
)
