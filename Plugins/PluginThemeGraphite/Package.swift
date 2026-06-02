// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginThemeGraphite",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "PluginThemeGraphite",
            targets: ["PluginThemeGraphite"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "PluginThemeGraphite",
            dependencies: [
                "GitOKCoreKit",
            ],
            path: "Sources",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "PluginThemeGraphiteTests",
            dependencies: ["PluginThemeGraphite"],
            path: "Tests"
        ),
    ]
)

