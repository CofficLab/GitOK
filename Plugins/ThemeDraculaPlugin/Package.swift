// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ThemeDraculaPlugin",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "ThemeDraculaPlugin",
            targets: ["ThemeDraculaPlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "ThemeDraculaPlugin",
            dependencies: [
                "GitOKCoreKit",
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

