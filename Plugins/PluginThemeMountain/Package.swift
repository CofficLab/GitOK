// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginThemeMountain",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [.library(name: "PluginThemeMountain", targets: ["ThemeMountainPlugin"])],
    dependencies: [
        .package(path: "../../Packages/KitGitOKCore"),
    ],
    targets: [
        .target(name: "ThemeMountainPlugin", dependencies: ["KitGitOKCore"], path: "Sources", resources: [.process("Localizable.xcstrings")]),
        .testTarget(name: "ThemeMountainPluginTests", dependencies: ["ThemeMountainPlugin"], path: "Tests"),
    ]
)
