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
        .package(path: "../KernelCore"),
        .package(path: "../ProviderDocsView"),
        .package(path: "../ProviderProjectReadme"),
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.0.2"),
    ],
    targets: [
        .target(
            name: "PluginProjectReadme",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "MarkdownUI", package: "swift-markdown-ui"),
                .product(name: "ProviderDocsView", package: "ProviderDocsView"),
                .product(name: "ProviderProjectReadme", package: "ProviderProjectReadme"),
            ]
        ),
    ]
)
