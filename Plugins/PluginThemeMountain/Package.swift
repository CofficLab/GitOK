// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginThemeMountain",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [.library(name: "PluginThemeMountain", targets: ["PluginThemeMountain"])],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(name: "PluginThemeMountain", dependencies: ["GitOKCoreKit"], path: "Sources", resources: [.process("Resources")]),
        .testTarget(name: "PluginThemeMountainTests", dependencies: ["PluginThemeMountain"], path: "Tests"),
    ]
)
