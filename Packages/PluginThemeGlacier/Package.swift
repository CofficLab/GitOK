// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginThemeGlacier",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [.library(name: "PluginThemeGlacier", targets: ["PluginThemeGlacier"])],
    dependencies: [
        .package(path: "../GitOKPluginKit"),
        .package(path: "../GitOKUI"),
    ],
    targets: [
        .target(name: "PluginThemeGlacier", dependencies: ["GitOKPluginKit", "GitOKUI"], path: "Sources/PluginThemeGlacier", resources: [.process("Resources")]),
        .testTarget(name: "PluginThemeGlacierTests", dependencies: ["PluginThemeGlacier"], path: "Tests/PluginThemeGlacierTests"),
    ]
)
