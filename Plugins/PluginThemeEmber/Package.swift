// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginThemeEmber",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginThemeEmber",
            targets: ["ThemeEmberPlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/KitGitOKCore"),
    ],
    targets: [
        .target(
            name: "ThemeEmberPlugin",
            dependencies: [
                "KitGitOKCore",
            ],
            path: "Sources",
            resources: [
                .process("Localizable.xcstrings"),
            ]
        ),
        .testTarget(
            name: "ThemeEmberPluginTests",
            dependencies: ["ThemeEmberPlugin"],
            path: "Tests"
        ),
    ]
)
