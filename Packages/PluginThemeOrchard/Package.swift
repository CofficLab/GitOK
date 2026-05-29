// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginThemeOrchard",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [.library(name: "PluginThemeOrchard", targets: ["PluginThemeOrchard"])],
    dependencies: [
        .package(path: "../GitOKPluginKit"),
        .package(path: "../GitOKUI"),
    ],
    targets: [
        .target(name: "PluginThemeOrchard", dependencies: ["GitOKPluginKit", "GitOKUI"], path: "Sources/PluginThemeOrchard", resources: [.process("Resources")]),
        .testTarget(name: "PluginThemeOrchardTests", dependencies: ["PluginThemeOrchard"], path: "Tests/PluginThemeOrchardTests"),
    ]
)
