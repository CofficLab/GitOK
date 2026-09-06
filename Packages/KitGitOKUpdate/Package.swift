// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KitGitOKUpdate",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "KitGitOKUpdate", targets: ["KitGitOKUpdate"]),
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.4"),
    ],
    targets: [
        .target(
            name: "KitGitOKUpdate",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle"),
            ],
            path: "Sources/KitGitOKUpdate"
        ),
        .testTarget(
            name: "KitGitOKUpdateTests",
            dependencies: ["KitGitOKUpdate"],
            path: "Tests/KitGitOKUpdateTests"
        ),
    ]
)
