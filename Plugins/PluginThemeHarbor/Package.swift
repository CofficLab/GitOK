// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginThemeHarbor",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [.library(name: "PluginThemeHarbor", targets: ["ThemeHarborPlugin"])],
    dependencies: [
        .package(path: "../../Packages/KitGitOKCore"),
    ],
    targets: [
        .target(name: "ThemeHarborPlugin", dependencies: ["KitGitOKCore"], path: "Sources", resources: [.process("Localizable.xcstrings")]),
        .testTarget(name: "ThemeHarborPluginTests", dependencies: ["ThemeHarborPlugin"], path: "Tests"),
    ]
)
