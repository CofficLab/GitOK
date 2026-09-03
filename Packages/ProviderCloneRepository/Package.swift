// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProviderCloneRepository",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "ProviderCloneRepository",
            targets: ["ProviderCloneRepository"]
        ),
    ],
    targets: [
        .target(
            name: "ProviderCloneRepository",
            path: "Sources/ProviderCloneRepository"
        ),
    ]
)
