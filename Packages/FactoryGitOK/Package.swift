// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FactoryGitOK",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "FactoryGitOK", targets: ["FactoryGitOK"]),
    ],
    dependencies: [
        .package(path: "../KernelCore"),
        .package(path: "../KitLocalization"),
        .package(path: "../LumiUI"),
        .package(path: "../PluginCommand"),
        .package(path: "../PluginLogoCoffic"),
        .package(path: "../PluginLogoManager"),
        .package(path: "../PluginProjects"),
        .package(path: "../PluginSettingGeneral"),
        .package(path: "../PluginSettingView"),
        .package(path: "../PluginStorage"),
        .package(path: "../PluginThemePack"),
        .package(path: "../ProviderCommand"),
        .package(path: "../ProviderContentView"),
        .package(path: "../ProviderDocsView"),
        .package(path: "../ProviderLogo"),
        .package(path: "../ProviderRailView"),
        .package(path: "../ProviderRootView"),
        .package(path: "../ProviderSettingView"),
        .package(path: "../ProviderProjects"),
        .package(path: "../ProviderSidebar"),
        .package(path: "../ProviderStorage"),
        .package(path: "../ProviderTheme"),
        .package(path: "../ProviderToolbar"),
    ],
    targets: [
        .target(
            name: "FactoryGitOK",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitLocalization", package: "KitLocalization"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderContentView", package: "ProviderContentView"),
                .product(name: "ProviderDocsView", package: "ProviderDocsView"),
                .product(name: "ProviderRootView", package: "ProviderRootView"),
                .product(name: "ProviderSettingView", package: "ProviderSettingView"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderSidebar", package: "ProviderSidebar"),
                .product(name: "ProviderStorage", package: "ProviderStorage"),
                .product(name: "ProviderTheme", package: "ProviderTheme"),
                .product(name: "ProviderToolbar", package: "ProviderToolbar"),
                .product(name: "PluginCommand", package: "PluginCommand"),
                .product(name: "PluginLogoCoffic", package: "PluginLogoCoffic"),
                .product(name: "PluginLogoManager", package: "PluginLogoManager"),
                .product(name: "PluginProjects", package: "PluginProjects"),
                .product(name: "PluginSettingGeneral", package: "PluginSettingGeneral"),
                .product(name: "PluginSettingView", package: "PluginSettingView"),
                .product(name: "PluginStorage", package: "PluginStorage"),
                .product(name: "PluginThemePack", package: "PluginThemePack"),
                .product(name: "ProviderCommand", package: "ProviderCommand"),
                .product(name: "ProviderLogo", package: "ProviderLogo"),
                .product(name: "ProviderRailView", package: "ProviderRailView"),
            ],
            path: "Sources/FactoryGitOK"
        ),
        .testTarget(
            name: "FactoryGitOKTests",
            dependencies: ["FactoryGitOK"],
            path: "Tests/FactoryGitOKTests"
        ),
    ]
)
