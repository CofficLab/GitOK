// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginThemeOrchard",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [.library(name: "PluginThemeOrchard", targets: ["ThemeOrchardPlugin"])],
    dependencies: [
        .package(path: "../../Packages/KitGitOKCore"),
    ],
    targets: [
        .target(name: "ThemeOrchardPlugin", dependencies: ["KitGitOKCore"], path: "Sources", resources: [.process("Localizable.xcstrings")]),
        .testTarget(name: "ThemeOrchardPluginTests", dependencies: ["ThemeOrchardPlugin"], path: "Tests"),
    ]
)
