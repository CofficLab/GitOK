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
        .package(path: "../../Packages/GitOKUI"),
    ],
    targets: [
        .target(
            name: "PluginThemeWinter",
            dependencies: [
                "GitOKCoreKit",
                "GitOKUI",
            ],
            path: "Sources/PluginThemeWinter",
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

