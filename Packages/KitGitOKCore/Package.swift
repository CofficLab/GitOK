// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KitGitOKCore",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "KitGitOKCore",
            targets: ["KitGitOKCore"]
        ),
    ],
    dependencies: [
        .package(path: "../GitOKUI"),
    ],
    targets: [
        .target(
            name: "KitGitOKCore",
            dependencies: [
                "GitOKUI",
            ],
            path: "Sources/KitGitOKCore",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "KitGitOKCoreTests",
            dependencies: ["KitGitOKCore"],
            path: "Tests"
        ),
    ]
)
