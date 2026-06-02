// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ThemeAuroraPlugin",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "ThemeAuroraPlugin",
            targets: ["ThemeAuroraPlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "ThemeAuroraPlugin",
            dependencies: [
                "GitOKCoreKit",
            ],
            path: "Sources",
            resources: [
                .process("Localizable.xcstrings"),
            ]
        ),
        .testTarget(
            name: "ThemeAuroraPluginTests",
            dependencies: ["ThemeAuroraPlugin"],
            path: "Tests"
        ),
    ]
)
