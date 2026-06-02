// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OpenAntigravityPlugin",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(name: "OpenAntigravityPlugin", targets: ["OpenAntigravityPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "OpenAntigravityPlugin",
            dependencies: ["GitOKCoreKit"],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "OpenAntigravityPluginTests",
            dependencies: ["OpenAntigravityPlugin"],
            path: "Tests"
        ),
    ]
)
