// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KitGit",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "KitGit", targets: ["KitGit"]),
    ],
    dependencies: [
        .package(path: "../KitGitOKLocalization"),
    ],
    targets: [
        .target(
            name: "KitGit",
            dependencies: [
                .product(name: "KitGitOKLocalization", package: "KitGitOKLocalization"),
            ],
            path: "Sources/KitGit",
            resources: [
                .process("../../Resources/Localizable.xcstrings")
            ]
        ),
        .testTarget(
            name: "KitGitTests",
            dependencies: ["KitGit"],
            path: "Tests/KitGitTests"
        ),
    ]
)
