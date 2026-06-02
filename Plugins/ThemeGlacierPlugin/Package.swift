// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ThemeGlacierPlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [.library(name: "ThemeGlacierPlugin", targets: ["ThemeGlacierPlugin"])],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(name: "ThemeGlacierPlugin", dependencies: ["GitOKCoreKit"], path: "Sources", resources: [.process("Resources")]),
        .testTarget(name: "ThemeGlacierPluginTests", dependencies: ["ThemeGlacierPlugin"], path: "Tests"),
    ]
)
