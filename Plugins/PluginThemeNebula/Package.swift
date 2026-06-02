// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginThemeNebula",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [.library(name: "PluginThemeNebula", targets: ["PluginThemeNebula"])],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "PluginThemeNebula",
            dependencies: ["GitOKCoreKit"],
            path: "Sources",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginThemeNebulaTests",
            dependencies: ["PluginThemeNebula"],
            path: "Tests"
        ),
    ]
)
