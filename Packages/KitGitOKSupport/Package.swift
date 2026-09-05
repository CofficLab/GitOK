// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KitGitOKSupport",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "KitGitOKSupport", targets: ["KitGitOKSupport"]),
    ],
    targets: [
        .target(
            name: "KitGitOKSupport",
            path: "Sources/KitGitOKSupport"
        ),
        .testTarget(
            name: "KitGitOKSupportTests",
            dependencies: ["KitGitOKSupport"],
            path: "Tests/KitGitOKSupportTests"
        ),
    ]
)
