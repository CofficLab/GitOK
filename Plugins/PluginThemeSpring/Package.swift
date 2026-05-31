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
        .package(path: "../../Packages/GitOKPluginKit"),
        .package(path: "../../Packages/GitOKUI"),
    ],
    targets: [
        .target(
            name: "PluginThemeSpring",
            dependencies: [
                "GitOKPluginKit",
                "GitOKUI",
            ],
            path: "Sources/PluginThemeSpring",
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
