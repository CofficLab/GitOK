// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginThemeSummer",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginThemeSummer",
            targets: ["ThemeSummerPlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/KitGitOKCore"),
    ],
    targets: [
        .target(
            name: "ThemeSummerPlugin",
            dependencies: [
                "KitGitOKCore",
            ],
            path: "Sources",
            resources: [
                .process("Localizable.xcstrings"),
            ]
        ),
        .testTarget(
            name: "ThemeSummerPluginTests",
            dependencies: ["ThemeSummerPlugin"],
            path: "Tests"
        ),
    ]
)

