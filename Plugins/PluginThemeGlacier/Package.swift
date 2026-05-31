// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginThemeGlacier",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [.library(name: "PluginThemeGlacier", targets: ["PluginThemeGlacier"])],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
        .package(path: "../../Packages/GitOKUI"),
    ],
    targets: [
        .target(name: "PluginThemeGlacier", dependencies: ["GitOKCoreKit", "GitOKUI"], path: "Sources/PluginThemeGlacier", resources: [.process("Resources")]),
        .testTarget(name: "PluginThemeGlacierTests", dependencies: ["PluginThemeGlacier"], path: "Tests"),
    ]
)
