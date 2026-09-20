// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProviderProjectReadme",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "ProviderProjectReadme", targets: ["ProviderProjectReadme"]),
    ],
    targets: [
        .target(name: "ProviderProjectReadme"),
    ]
)
