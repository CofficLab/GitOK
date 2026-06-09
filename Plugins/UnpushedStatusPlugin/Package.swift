// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "UnpushedStatusPlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "UnpushedStatusPlugin", targets: ["UnpushedStatusPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitCoreKit"),
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "UnpushedStatusPlugin",
            dependencies: [
                "GitCoreKit",
                "GitOKCoreKit",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "UnpushedStatusPluginTests",
            dependencies: ["UnpushedStatusPlugin"],
            path: "Tests"
        ),
    ]
)
