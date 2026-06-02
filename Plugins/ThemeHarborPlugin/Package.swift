// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ThemeHarborPlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [.library(name: "ThemeHarborPlugin", targets: ["ThemeHarborPlugin"])],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(name: "ThemeHarborPlugin", dependencies: ["GitOKCoreKit"], path: "Sources", resources: [.process("Resources")]),
        .testTarget(name: "ThemeHarborPluginTests", dependencies: ["ThemeHarborPlugin"], path: "Tests"),
    ]
)
