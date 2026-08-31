// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginOpenLumi",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginOpenLumi",
            targets: ["OpenLumiPlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/KitGitOKCore"),
        .package(path: "../../Packages/KitGitOKSupport"),
        .package(path: "../../Packages/GitOKUI"),
    ],
    targets: [
        .target(
            name: "OpenLumiPlugin",
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
            name: "OpenLumiPluginTests",
            dependencies: ["OpenLumiPlugin"],
            path: "Tests"
        ),
    ]
)
