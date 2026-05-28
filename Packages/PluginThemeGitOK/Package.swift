// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginThemeGitOK",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "PluginThemeGitOK",
            targets: ["PluginThemeGitOK"]
        ),
    ],
    dependencies: [
        .package(path: "../GitOKPluginKit"),
        .package(path: "../GitOKUI"),
    ],
    targets: [
        .target(
            name: "PluginThemeGitOK",
            dependencies: [
                "GitOKPluginKit",
                "GitOKUI",
            ],
            path: "Sources/PluginThemeGitOK",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "PluginThemeGitOKTests",
            dependencies: ["PluginThemeGitOK"],
            path: "Tests/PluginThemeGitOKTests"
        ),
    ]
)
