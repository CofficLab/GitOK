// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginOpenFinder",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginOpenFinder",
            targets: ["OpenFinderPlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/KitGitOKCore"),
        .package(path: "../../Packages/KitGitOKSupport"),
        .package(path: "../../Packages/GitOKUI"),
    ],
    targets: [
        .target(
            name: "OpenFinderPlugin",
            dependencies: [
                "KitGitOKCore",
                .product(name: "KitGitOKDesign", package: "KitGitOKSupport"),
                "GitOKUI",
            ],
            path: "Sources",
            resources: [
                .process("Localizable.xcstrings"),
            ]
        ),
        .testTarget(
            name: "OpenFinderPluginTests",
            dependencies: ["OpenFinderPlugin"],
            path: "Tests"
        ),
    ]
)
