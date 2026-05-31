// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginThemeSummer",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "PluginThemeSummer",
            targets: ["PluginThemeSummer"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKPluginKit"),
        .package(path: "../../Packages/GitOKUI"),
    ],
    targets: [
        .target(
            name: "PluginThemeSummer",
            dependencies: [
                "GitOKPluginKit",
                "GitOKUI",
            ],
            path: "Sources/PluginThemeSummer",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "PluginThemeSummerTests",
            dependencies: ["PluginThemeSummer"],
            path: "Tests/PluginThemeSummerTests"
        ),
    ]
)

