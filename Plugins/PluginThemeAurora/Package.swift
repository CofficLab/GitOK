// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginThemeAurora",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginThemeAurora",
            targets: ["ThemeAuroraPlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/KitGitOKCore"),
    ],
    targets: [
        .target(
            name: "ThemeAuroraPlugin",
            dependencies: [
                "KitGitOKCore",
            ],
            path: "Sources",
            resources: [
                .process("Localizable.xcstrings"),
            ]
        ),
        .testTarget(
            name: "ThemeAuroraPluginTests",
            dependencies: ["ThemeAuroraPlugin"],
            path: "Tests"
        ),
    ]
)
