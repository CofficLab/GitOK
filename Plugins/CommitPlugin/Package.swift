// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CommitPlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "CommitPlugin", targets: ["CommitPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "CommitPlugin",
            dependencies: ["GitOKCoreKit"],
            path: "Sources"
        ),
        .testTarget(
            name: "CommitPluginTests",
            dependencies: ["CommitPlugin"],
            path: "Tests"
        ),
    ]
)
