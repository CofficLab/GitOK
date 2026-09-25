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
        .package(url: "https://github.com/CofficLab/LumiKernel.git", branch: "main"),
        .package(path: "../ProviderStorage"),
    ],
    targets: [
        .target(
            name: "ProviderAutoPush",
            dependencies: [
                .product(name: "KernelCore", package: "LumiKernel"),
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
