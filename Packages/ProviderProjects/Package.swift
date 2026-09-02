// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProviderProjects",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "ProviderProjects",
            targets: ["ProviderProjects"]
        ),
    ],
    targets: [
        .target(
            name: "ProviderProjects",
            path: "Sources/ProviderProjects"
        ),
        .testTarget(
            name: "ProviderProjectsTests",
            dependencies: ["ProviderProjects"],
            path: "Tests/ProviderProjectsTests"
        ),
    ]
)
