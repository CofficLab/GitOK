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
        .package(url: "https://github.com/CofficLab/LumiProviders.git", from: "1.2.2"),
        .package(url: "https://github.com/CofficLab/LumiKernel.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "ProviderAutoPush",
            dependencies: [
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "ProviderStorage", package: "LumiProviders"),
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
