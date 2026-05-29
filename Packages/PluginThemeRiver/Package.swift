// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginThemeRiver",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "PluginThemeRiver",
            targets: ["PluginThemeRiver"]
        ),
    ],
    dependencies: [
        .package(path: "../GitOKPluginKit"),
        .package(path: "../GitOKUI"),
    ],
    targets: [
        .target(
            name: "PluginThemeRiver",
            dependencies: [
                "GitOKPluginKit",
                "GitOKUI",
            ],
            path: "Sources/PluginThemeRiver",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "PluginThemeRiverTests",
            dependencies: ["PluginThemeRiver"],
            path: "Tests/PluginThemeRiverTests"
        ),
    ]
)
