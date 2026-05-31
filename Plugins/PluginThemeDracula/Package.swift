// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginThemeDracula",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "PluginThemeDracula",
            targets: ["PluginThemeDracula"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKPluginKit"),
        .package(path: "../../Packages/GitOKUI"),
    ],
    targets: [
        .target(
            name: "PluginThemeDracula",
            dependencies: [
                "GitOKPluginKit",
                "GitOKUI",
            ],
            path: "Sources/PluginThemeDracula",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "PluginThemeDraculaTests",
            dependencies: ["PluginThemeDracula"],
            path: "Tests"
        ),
    ]
)

