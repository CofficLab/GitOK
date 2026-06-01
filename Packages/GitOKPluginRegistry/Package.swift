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
        .package(path: "../../Plugins/PluginActivityStatus"),
        .package(path: "../../Plugins/PluginAutoPush"),
        .package(path: "../../Plugins/PluginBranch"),
        .package(path: "../../Plugins/PluginConflictResolver"),
        .package(path: "../../Plugins/PluginFileInfo"),
        .package(path: "../../Plugins/PluginGitIgnore"),
        .package(path: "../../Plugins/PluginGitLFS"),
        .package(path: "../../Plugins/PluginLicense"),
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
        .package(path: "../../Plugins/PluginReadme"),
        .package(path: "../../Plugins/PluginRemoteRepository"),
        .package(path: "../../Plugins/PluginSettingsButton"),
        .package(path: "../../Plugins/PluginSmartMerge"),
        .package(path: "../../Plugins/PluginStash"),
        .package(path: "../../Plugins/PluginSubmodule"),
        .package(path: "../../Plugins/PluginThemeStatusBar"),
    ],
    targets: [
        .target(
            name: "GitOKPluginRegistry",
            dependencies: [
                "GitOKCoreKit",
                "PluginActivityStatus",
                "PluginAutoPush",
                "PluginBranch",
                "PluginConflictResolver",
                "PluginFileInfo",
                "PluginGitIgnore",
                "PluginGitLFS",
                "PluginLicense",
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
                "PluginReadme",
                "PluginRemoteRepository",
                "PluginSettingsButton",
                "PluginSmartMerge",
                "PluginStash",
                "PluginSubmodule",
                "PluginThemeStatusBar",
            ],
            path: "Sources/GitOKPluginRegistry"
        ),
    ]
)
