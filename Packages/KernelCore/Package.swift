// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KernelCore",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "KernelCore", targets: ["KernelCore"]),
    ],
    targets: [
        .target(
            name: "KernelCore",
            path: "Sources/KernelCore"
        ),
        .testTarget(
            name: "KernelCoreTests",
            dependencies: ["KernelCore"],
            path: "Tests"
        ),
    ]
)
