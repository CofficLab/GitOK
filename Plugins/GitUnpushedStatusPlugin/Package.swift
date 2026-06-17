// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GitUnpushedStatusPlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "GitUnpushedStatusPlugin", targets: ["GitUnpushedStatusPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitCoreKit"),
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "GitUnpushedStatusPlugin",
            dependencies: [
                "GitCoreKit",
                "GitOKCoreKit",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "GitUnpushedStatusPluginTests",
            dependencies: ["GitUnpushedStatusPlugin"],
            path: "Tests"
        ),
    ]
)
