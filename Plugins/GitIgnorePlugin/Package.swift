// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GitIgnorePlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "GitIgnorePlugin", targets: ["GitIgnorePlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "GitIgnorePlugin",
            dependencies: ["GitOKCoreKit"],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "GitIgnorePluginTests",
            dependencies: ["GitIgnorePlugin"],
            path: "Tests"
        ),
    ]
)
