// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ThemeOrchardPlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [.library(name: "ThemeOrchardPlugin", targets: ["ThemeOrchardPlugin"])],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(name: "ThemeOrchardPlugin", dependencies: ["GitOKCoreKit"], path: "Sources", resources: [.process("Localizable.xcstrings")]),
        .testTarget(name: "ThemeOrchardPluginTests", dependencies: ["ThemeOrchardPlugin"], path: "Tests"),
    ]
)
