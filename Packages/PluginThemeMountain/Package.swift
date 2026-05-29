// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginThemeMountain",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [.library(name: "PluginThemeMountain", targets: ["PluginThemeMountain"])],
    dependencies: [
        .package(path: "../GitOKPluginKit"),
        .package(path: "../GitOKUI"),
    ],
    targets: [
        .target(name: "PluginThemeMountain", dependencies: ["GitOKPluginKit", "GitOKUI"], path: "Sources/PluginThemeMountain", resources: [.process("Resources")]),
        .testTarget(name: "PluginThemeMountainTests", dependencies: ["PluginThemeMountain"], path: "Tests/PluginThemeMountainTests"),
    ]
)
