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
        .package(path: "../../Packages/GitOKCoreKit"),
        .package(path: "../../Packages/GitOKUI"),
    ],
    targets: [
        .target(
            name: "PluginThemeDracula",
            dependencies: [
                "GitOKCoreKit",
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

