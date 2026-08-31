// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginThemeSpring",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginThemeSpring",
            targets: ["ThemeSpringPlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/KitGitOKCore"),
    ],
    targets: [
        .target(
            name: "ThemeSpringPlugin",
            dependencies: [
                "KitGitOKCore",
            ],
            path: "Sources",
            resources: [
                .process("Localizable.xcstrings"),
            ]
        ),
        .testTarget(
            name: "ThemeSpringPluginTests",
            dependencies: ["ThemeSpringPlugin"],
            path: "Tests"
        ),
    ]
)
