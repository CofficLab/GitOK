// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginGitDetail",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "PluginGitDetail", targets: ["PluginGitDetail"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "PluginGitDetail",
            dependencies: ["GitOKCoreKit"],
            path: "Sources/PluginGitDetail",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginGitDetailTests",
            dependencies: ["PluginGitDetail"],
            path: "Tests"
        ),
    ]
)
