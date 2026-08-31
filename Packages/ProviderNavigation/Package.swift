// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProviderNavigation",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "ProviderNavigation", targets: ["ProviderNavigation"]),
    ],
    targets: [
        .target(name: "ProviderNavigation", path: "Sources"),
    ]
)
