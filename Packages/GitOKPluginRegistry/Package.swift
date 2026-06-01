// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GitOKPluginRegistry",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "GitOKPluginRegistry",
            targets: ["GitOKPluginRegistry"]
        ),
    ],
    dependencies: [
        .package(path: "../GitOKCoreKit"),
        .package(path: "../../Plugins/PluginOpenVSCode"),
    ],
    targets: [
        .target(
            name: "GitOKPluginRegistry",
            dependencies: [
                "GitOKCoreKit",
                "PluginOpenVSCode",
            ],
            path: "Sources/GitOKPluginRegistry"
        ),
    ]
)
