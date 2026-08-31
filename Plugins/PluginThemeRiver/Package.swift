// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginThemeRiver",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginThemeRiver",
            targets: ["ThemeRiverPlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/KitGitOKCore"),
    ],
    targets: [
        .target(
            name: "ThemeRiverPlugin",
            dependencies: [
                "KitGitOKCore",
            ],
            path: "Sources",
            resources: [
                .process("Localizable.xcstrings"),
            ]
        ),
        .testTarget(
            name: "ThemeRiverPluginTests",
            dependencies: ["ThemeRiverPlugin"],
            path: "Tests"
        ),
    ]
)
