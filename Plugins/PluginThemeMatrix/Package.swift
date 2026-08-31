// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginThemeMatrix",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginThemeMatrix",
            targets: ["ThemeMatrixPlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/KitGitOKCore"),
    ],
    targets: [
        .target(
            name: "ThemeMatrixPlugin",
            dependencies: [
                "KitGitOKCore",
            ],
            path: "Sources",
            resources: [
                .process("Localizable.xcstrings"),
            ]
        ),
        .testTarget(
            name: "ThemeMatrixPluginTests",
            dependencies: ["ThemeMatrixPlugin"],
            path: "Tests"
        ),
    ]
)
