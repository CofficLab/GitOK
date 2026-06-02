// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ThemeNebulaPlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [.library(name: "ThemeNebulaPlugin", targets: ["ThemeNebulaPlugin"])],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "ThemeNebulaPlugin",
            dependencies: ["GitOKCoreKit"],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "ThemeNebulaPluginTests",
            dependencies: ["ThemeNebulaPlugin"],
            path: "Tests"
        ),
    ]
)
