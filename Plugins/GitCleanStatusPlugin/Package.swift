// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GitCleanStatusPlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "GitCleanStatusPlugin", targets: ["GitCleanStatusPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitCoreKit"),
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "GitCleanStatusPlugin",
            dependencies: [
                "GitCoreKit",
                "GitOKCoreKit",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "GitCleanStatusPluginTests",
            dependencies: ["GitCleanStatusPlugin"],
            path: "Tests"
        ),
    ]
)
