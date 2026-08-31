// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginThemeNebula",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [.library(name: "PluginThemeNebula", targets: ["ThemeNebulaPlugin"])],
    dependencies: [
        .package(path: "../../Packages/KitGitOKCore"),
    ],
    targets: [
        .target(
            name: "ThemeNebulaPlugin",
            dependencies: ["KitGitOKCore"],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "ThemeNebulaPluginTests",
            dependencies: ["ThemeNebulaPlugin"],
            path: "Tests"
        ),
    ]
)
