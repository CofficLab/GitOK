// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ThemeMountainPlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [.library(name: "ThemeMountainPlugin", targets: ["ThemeMountainPlugin"])],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(name: "ThemeMountainPlugin", dependencies: ["GitOKCoreKit"], path: "Sources", resources: [.process("Localizable.xcstrings")]),
        .testTarget(name: "ThemeMountainPluginTests", dependencies: ["ThemeMountainPlugin"], path: "Tests"),
    ]
)
