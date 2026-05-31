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
        .package(path: "../../Packages/GitOKPluginKit"),
        .package(path: "../../Packages/GitOKUI"),
    ],
    targets: [
        .target(
            name: "PluginThemeMatrix",
            dependencies: [
                "GitOKPluginKit",
                "GitOKUI",
            ],
            path: "Sources/PluginThemeMatrix",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "PluginThemeMatrixTests",
            dependencies: ["PluginThemeMatrix"],
            path: "Tests/PluginThemeMatrixTests"
        ),
    ]
)
