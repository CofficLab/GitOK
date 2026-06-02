// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginThemeSpring",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "PluginThemeSpring",
            targets: ["PluginThemeSpring"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "PluginThemeSpring",
            dependencies: [
                "GitOKCoreKit",
            ],
            path: "Sources",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "PluginThemeSpringTests",
            dependencies: ["PluginThemeSpring"],
            path: "Tests"
        ),
    ]
)
