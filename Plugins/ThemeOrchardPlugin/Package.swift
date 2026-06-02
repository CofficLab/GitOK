// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ThemeOrchardPlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [.library(name: "ThemeOrchardPlugin", targets: ["ThemeOrchardPlugin"])],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(name: "ThemeOrchardPlugin", dependencies: ["GitOKCoreKit"], path: "Sources", resources: [.process("Resources")]),
        .testTarget(name: "ThemeOrchardPluginTests", dependencies: ["ThemeOrchardPlugin"], path: "Tests"),
    ]
)
