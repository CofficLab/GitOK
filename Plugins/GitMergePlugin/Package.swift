// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GitMergePlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "GitMergePlugin", targets: ["GitMergePlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitCoreKit"),
        .package(path: "../../Packages/GitOKCoreKit"),
        .package(path: "../../Packages/GitOKUI"),
    ],
    targets: [
        .target(
            name: "GitMergePlugin",
            dependencies: [
                "GitCoreKit",
                "GitOKCoreKit",
                "GitOKUI",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "GitMergePluginTests",
            dependencies: ["GitMergePlugin"],
            path: "Tests"
        ),
    ]
)
