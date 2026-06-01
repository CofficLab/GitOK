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
        .package(path: "../../Plugins/PluginOpenAntigravity"),
        .package(path: "../../Plugins/PluginOpenCursor"),
        .package(path: "../../Plugins/PluginOpenFinder"),
        .package(path: "../../Plugins/PluginOpenGitHubDesktop"),
        .package(path: "../../Plugins/PluginOpenKiro"),
        .package(path: "../../Plugins/PluginOpenRemote"),
        .package(path: "../../Plugins/PluginOpenTerminal"),
        .package(path: "../../Plugins/PluginOpenTrae"),
        .package(path: "../../Plugins/PluginOpenVSCode"),
        .package(path: "../../Plugins/PluginOpenXcode"),
    ],
    targets: [
        .target(
            name: "GitOKPluginRegistry",
            dependencies: [
                "GitOKCoreKit",
                "PluginOpenAntigravity",
                "PluginOpenCursor",
                "PluginOpenFinder",
                "PluginOpenGitHubDesktop",
                "PluginOpenKiro",
                "PluginOpenRemote",
                "PluginOpenTerminal",
                "PluginOpenTrae",
                "PluginOpenVSCode",
                "PluginOpenXcode",
            ],
            path: "Sources/GitOKPluginRegistry"
        ),
    ]
)
