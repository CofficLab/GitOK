// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginThemeWinter",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "PluginThemeWinter",
            targets: ["PluginThemeWinter"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "PluginThemeWinter",
            dependencies: [
                "GitOKCoreKit",
            ],
            path: "Sources",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "PluginThemeWinterTests",
            dependencies: ["PluginThemeWinter"],
            path: "Tests"
        ),
    ]
)

