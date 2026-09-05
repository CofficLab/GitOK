// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProviderAutoPush",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "ProviderAutoPush",
            targets: ["ProviderAutoPush"]
        ),
    ],
    dependencies: [
        .package(path: "../KernelCore"),
        .package(path: "../ProviderStorage"),
    ],
    targets: [
        .target(
            name: "ProviderAutoPush",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "ProviderStorage", package: "ProviderStorage"),
            ],
            path: "Sources/ProviderAutoPush"
        ),
        .testTarget(
            name: "ProviderAutoPushTests",
            dependencies: ["ProviderAutoPush"],
            path: "Tests/ProviderAutoPushTests"
        ),
    ]
)
