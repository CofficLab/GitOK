// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginThemeOneDark",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginThemeOneDark",
            targets: ["ThemeOneDarkPlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/KitGitOKCore"),
    ],
    targets: [
        .target(
            name: "ThemeOneDarkPlugin",
            dependencies: [
                "KitGitOKCore",
            ],
            path: "Sources",
            resources: [
                .process("Localizable.xcstrings"),
            ]
        ),
        .testTarget(
            name: "ThemeOneDarkPluginTests",
            dependencies: ["ThemeOneDarkPlugin"],
            path: "Tests"
        ),
    ]
)

