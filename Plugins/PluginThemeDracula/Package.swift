// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginThemeDracula",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginThemeDracula",
            targets: ["ThemeDraculaPlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/KitGitOKCore"),
    ],
    targets: [
        .target(
            name: "ThemeDraculaPlugin",
            dependencies: [
                "KitGitOKCore",
            ],
            path: "Sources",
            resources: [
                .process("Localizable.xcstrings"),
            ]
        ),
        .testTarget(
            name: "ThemeDraculaPluginTests",
            dependencies: ["ThemeDraculaPlugin"],
            path: "Tests"
        ),
    ]
)

