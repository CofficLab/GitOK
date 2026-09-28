// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginProjectReadme",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PluginProjectReadme", targets: ["PluginProjectReadme"]),
    ],
    dependencies: [
        .package(url: "https://github.com/CofficLab/LumiKernel.git", branch: "main"),
        .package(path: "../ProviderProjectReadme"),
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.0.2"),
        .package(url: "https://github.com/CofficLab/LumiProviders.git", from: "1.2.2")
    ],
    targets: [
        .target(
            name: "PluginProjectReadme",
            dependencies: [
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "MarkdownUI", package: "swift-markdown-ui"),
                .product(name: "ProviderDocsView", package: "LumiProviders"),
                .product(name: "ProviderProjectReadme", package: "ProviderProjectReadme"),
            ]
        ),
        .testTarget(
            name: "PluginProjectReadmeTests",
            dependencies: ["PluginProjectReadme"],
            path: "Tests/PluginProjectReadmeTests"
        ),
    ]
)
