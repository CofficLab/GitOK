// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProviderWorkspaceScene",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "ProviderWorkspaceScene",
            targets: ["ProviderWorkspaceScene"]
        ),
    ],
    targets: [
        .target(
            name: "ProviderWorkspaceScene",
            path: "Sources/ProviderWorkspaceScene"
        ),
        .testTarget(
            name: "ProviderWorkspaceSceneTests",
            dependencies: ["ProviderWorkspaceScene"]
        ),
    ]
)
