// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KitGit",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "KitGit", targets: ["KitGit"]),
    ],
    targets: [
        .target(
            name: "KitGit",
            path: "Sources/KitGit"
        ),
        .testTarget(
            name: "KitGitTests",
            dependencies: ["KitGit"],
            path: "Tests/KitGitTests"
        ),
    ]
)
