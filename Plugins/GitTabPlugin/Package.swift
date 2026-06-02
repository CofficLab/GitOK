// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GitTabPlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "GitTabPlugin", targets: ["GitTabPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "GitTabPlugin",
            dependencies: ["GitOKCoreKit"],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "GitTabPluginTests",
            dependencies: ["GitTabPlugin"],
            path: "Tests"
        ),
    ]
)
