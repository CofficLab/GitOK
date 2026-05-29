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
        .package(path: "../GitOKPluginKit"),
        .package(path: "../GitOKUI"),
    ],
    targets: [
        .target(
            name: "PluginThemeGraphite",
            dependencies: [
                "GitOKPluginKit",
                "GitOKUI",
            ],
            path: "Sources/PluginThemeGraphite",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "PluginThemeGraphiteTests",
            dependencies: ["PluginThemeGraphite"],
            path: "Tests/PluginThemeGraphiteTests"
        ),
    ]
)

