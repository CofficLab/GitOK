// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProviderGit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "ProviderGit", targets: ["ProviderGit"]),
    ],
    targets: [
        .target(name: "ProviderGit", path: "Sources"),
    ]
)
