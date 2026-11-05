// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KitGitOKLocalization",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "KitGitOKLocalization", targets: ["KitGitOKLocalization"]),
    ],
    targets: [
        .target(
            name: "KitGitOKLocalization",
            path: "Sources/KitGitOKLocalization"
        ),
        .testTarget(
            name: "KitGitOKLocalizationTests",
            dependencies: ["KitGitOKLocalization"],
            path: "Tests/KitGitOKLocalizationTests"
        ),
    ]
)
