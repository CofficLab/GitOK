// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KitOpenIn",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "KitOpenIn",
            targets: ["KitOpenIn"]
        ),
    ],
    dependencies: [
        .package(path: "../KernelCore"),
        .package(path: "../LumiUI"),
        .package(path: "../ProviderProjects"),
        .package(path: "../ProviderToolbar"),
    ],
    targets: [
        .target(
            name: "KitOpenIn",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderToolbar", package: "ProviderToolbar"),
            ],
            path: "Sources/KitOpenIn"
        ),
        .testTarget(
            name: "KitOpenInTests",
            dependencies: ["KitOpenIn"],
            path: "Tests/KitOpenInTests"
        ),
    ]
)
