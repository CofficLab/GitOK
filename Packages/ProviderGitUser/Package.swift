// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProviderGitUser",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "ProviderGitUser",
            targets: ["ProviderGitUser"]
        ),
    ],
    targets: [
        .target(
            name: "ProviderGitUser",
            path: "Sources/ProviderGitUser"
        ),
        .testTarget(
            name: "ProviderGitUserTests",
            dependencies: ["ProviderGitUser"],
            path: "Tests/ProviderGitUserTests"
        ),
    ]
)
