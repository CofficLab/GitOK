// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProviderActivity",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "ProviderActivity",
            targets: ["ProviderActivity"]
        ),
    ],
    targets: [
        .target(
            name: "ProviderActivity",
            path: "Sources/ProviderActivity"
        ),
        .testTarget(
            name: "ProviderActivityTests",
            dependencies: ["ProviderActivity"],
            path: "Tests/ProviderActivityTests"
        ),
    ]
)
