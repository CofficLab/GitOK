// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProviderPluginControl",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "ProviderPluginControl",
            targets: ["ProviderPluginControl"]
        ),
    ],
    dependencies: [
        .package(path: "../KernelCore"),
    ],
    targets: [
        .target(
            name: "ProviderPluginControl",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
            ],
            path: "Sources/ProviderPluginControl"
        ),
        .testTarget(
            name: "ProviderPluginControlTests",
            dependencies: ["ProviderPluginControl"],
            path: "Tests/ProviderPluginControlTests"
        ),
    ]
)
