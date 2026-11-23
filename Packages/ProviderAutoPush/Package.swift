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
        .package(url: "https://github.com/lumi-softworks/LumiProviders.git", from: "1.27.0"),
        .package(url: "https://github.com/lumi-softworks/LumiKernel.git", from: "1.1.2"),
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
