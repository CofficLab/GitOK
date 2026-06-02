// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginThemeOrchard",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [.library(name: "PluginThemeOrchard", targets: ["PluginThemeOrchard"])],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(name: "PluginThemeOrchard", dependencies: ["GitOKCoreKit"], path: "Sources", resources: [.process("Resources")]),
        .testTarget(name: "PluginThemeOrchardTests", dependencies: ["PluginThemeOrchard"], path: "Tests"),
    ]
)
