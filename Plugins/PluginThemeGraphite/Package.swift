// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginThemeGraphite",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginThemeGraphite",
            targets: ["ThemeGraphitePlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/KitGitOKCore"),
    ],
    targets: [
        .target(
            name: "ThemeGraphitePlugin",
            dependencies: [
                "KitGitOKCore",
            ],
            path: "Sources",
            resources: [
                .process("Localizable.xcstrings"),
            ]
        ),
        .testTarget(
            name: "ThemeGraphitePluginTests",
            dependencies: ["ThemeGraphitePlugin"],
            path: "Tests"
        ),
    ]
)

