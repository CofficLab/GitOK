// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginThemeMatrix",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "PluginThemeMatrix",
            targets: ["PluginThemeMatrix"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "PluginThemeMatrix",
            dependencies: [
                "GitOKCoreKit",
            ],
            path: "Sources",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "PluginThemeMatrixTests",
            dependencies: ["PluginThemeMatrix"],
            path: "Tests"
        ),
    ]
)
