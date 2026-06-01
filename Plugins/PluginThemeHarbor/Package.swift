// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginThemeHarbor",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [.library(name: "PluginThemeHarbor", targets: ["PluginThemeHarbor"])],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(name: "PluginThemeHarbor", dependencies: ["GitOKCoreKit"], path: "Sources/PluginThemeHarbor", resources: [.process("Resources")]),
        .testTarget(name: "PluginThemeHarborTests", dependencies: ["PluginThemeHarbor"], path: "Tests"),
    ]
)
