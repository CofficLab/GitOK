// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginThemeGlacier",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [.library(name: "PluginThemeGlacier", targets: ["ThemeGlacierPlugin"])],
    dependencies: [
        .package(path: "../../Packages/KitGitOKCore"),
    ],
    targets: [
        .target(name: "ThemeGlacierPlugin", dependencies: ["KitGitOKCore"], path: "Sources", resources: [.process("Localizable.xcstrings")]),
        .testTarget(name: "ThemeGlacierPluginTests", dependencies: ["ThemeGlacierPlugin"], path: "Tests"),
    ]
)
