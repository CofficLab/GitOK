// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginOpenTerminal",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginOpenTerminal",
            targets: ["OpenTerminalPlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/KitGitOKCore"),
        .package(path: "../../Packages/KitGitOKSupport"),
        .package(path: "../../Packages/GitOKUI"),
    ],
    targets: [
        .target(
            name: "OpenTerminalPlugin",
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
            name: "OpenTerminalPluginTests",
            dependencies: ["OpenTerminalPlugin"],
            path: "Tests"
        ),
    ]
)
