// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginThemeOneDark",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "PluginThemeOneDark",
            targets: ["PluginThemeOneDark"]
        ),
    ],
    dependencies: [
        .package(path: "../GitOKPluginKit"),
        .package(path: "../GitOKUI"),
    ],
    targets: [
        .target(
            name: "PluginThemeOneDark",
            dependencies: [
                "GitOKPluginKit",
                "GitOKUI",
            ],
            path: "Sources/PluginThemeOneDark",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "PluginThemeOneDarkTests",
            dependencies: ["PluginThemeOneDark"],
            path: "Tests/PluginThemeOneDarkTests"
        ),
    ]
)

