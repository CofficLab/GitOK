// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginThemeMidnight",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginThemeMidnight",
            targets: ["ThemeMidnightPlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/KitGitOKCore"),
    ],
    targets: [
        .target(
            name: "ThemeMidnightPlugin",
            dependencies: [
                "KitGitOKCore",
            ],
            path: "Sources",
            resources: [
                .process("Localizable.xcstrings"),
            ]
        ),
        .testTarget(
            name: "ThemeMidnightPluginTests",
            dependencies: ["ThemeMidnightPlugin"],
            path: "Tests"
        ),
    ]
)
