// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ThemeRiverPlugin",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "ThemeRiverPlugin",
            targets: ["ThemeRiverPlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "ThemeRiverPlugin",
            dependencies: [
                "GitOKCoreKit",
            ],
            path: "Sources",
            resources: [
                .process("Localizable.xcstrings"),
            ]
        ),
        .testTarget(
            name: "ThemeRiverPluginTests",
            dependencies: ["ThemeRiverPlugin"],
            path: "Tests"
        ),
    ]
)
