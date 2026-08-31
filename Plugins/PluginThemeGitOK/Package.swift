// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginThemeGitOK",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginThemeGitOK",
            targets: ["ThemeGitOKPlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/KitGitOKCore"),
    ],
    targets: [
        .target(
            name: "ThemeGitOKPlugin",
            dependencies: [
                "KitGitOKCore",
            ],
            path: "Sources",
            resources: [
                .process("Localizable.xcstrings"),
            ]
        ),
        .testTarget(
            name: "ThemeGitOKPluginTests",
            dependencies: ["ThemeGitOKPlugin"],
            path: "Tests"
        ),
    ]
)
