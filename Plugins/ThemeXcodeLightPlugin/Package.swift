// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ThemeXcodeLightPlugin",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "ThemeXcodeLightPlugin",
            targets: ["ThemeXcodeLightPlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "ThemeXcodeLightPlugin",
            dependencies: [
                "GitOKCoreKit",
            ],
            path: "Sources",
            resources: [
                .process("Localizable.xcstrings"),
            ]
        ),
        .testTarget(
            name: "ThemeXcodeLightPluginTests",
            dependencies: ["ThemeXcodeLightPlugin"],
            path: "Tests"
        ),
    ]
)

