// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginReadme",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "PluginReadme", targets: ["PluginReadme"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKPluginKit"),
        .package(path: "../../Packages/ProjectSupportKit"),
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.4.1"),
    ],
    targets: [
        .target(
            name: "PluginReadme",
            dependencies: [
                "GitOKPluginKit",
                "ProjectSupportKit",
                .product(name: "MarkdownUI", package: "swift-markdown-ui"),
            ],
            path: "Sources/PluginReadme",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PluginReadmeTests",
            dependencies: ["PluginReadme"],
            path: "Tests/PluginReadmeTests"
        ),
    ]
)
