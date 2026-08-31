// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginThemeXcodeLight",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginThemeXcodeLight",
            targets: ["ThemeXcodeLightPlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/KitGitOKCore"),
    ],
    targets: [
        .target(
            name: "ThemeXcodeLightPlugin",
            dependencies: [
                "KitGitOKCore",
            ],
            path: "Sources",
            resources: [
                .process("Localizable.xcstrings"),
            ]
        ),
        .testTarget(
            name: "ThemeXcodeLightPluginTests",
            dependencies: ["ThemeXcodeLightPlugin"],
            path: "Tests"
        ),
    ]
)

