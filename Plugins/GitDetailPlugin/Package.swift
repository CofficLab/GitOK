// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GitDetailPlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "GitDetailPlugin", targets: ["GitDetailPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "GitDetailPlugin",
            dependencies: ["GitOKCoreKit"],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "GitDetailPluginTests",
            dependencies: ["GitDetailPlugin"],
            path: "Tests"
        ),
    ]
)
