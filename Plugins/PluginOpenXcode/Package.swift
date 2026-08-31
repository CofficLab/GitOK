// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginOpenXcode",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginOpenXcode",
            targets: ["OpenXcodePlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/KitGitOKCore"),
        .package(path: "../../Packages/KitGitOKSupport"),
        .package(path: "../../Packages/GitOKUI"),
    ],
    targets: [
        .target(
            name: "OpenXcodePlugin",
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
            name: "OpenXcodePluginTests",
            dependencies: ["OpenXcodePlugin"],
            path: "Tests"
        ),
    ]
)
