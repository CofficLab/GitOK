// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginToast",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [.library(name: "PluginToast", targets: ["PluginToast"])],
    dependencies: [
        .package(path: "../KitSuperLog"),
        .package(url: "https://github.com/CofficLab/LumiKernel.git", branch: "main"),
        .package(path: "../KitLocalization"),
        .package(path: "../ProviderDocsView"),
        .package(path: "../ProviderToast"),
        .package(path: "../ProviderRootView"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.2.1"),
    ],
    targets: [
        .target(
            name: "PluginToast",
            dependencies: [
                "KitSuperLog",
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "KitLocalization", package: "KitLocalization"),
                .product(name: "ProviderDocsView", package: "ProviderDocsView"),
                .product(name: "ProviderToast", package: "ProviderToast"),
                .product(name: "ProviderRootView", package: "ProviderRootView"),
                .product(name: "LumiUI", package: "LumiUI"),
            ],
            path: "Sources/PluginToast",
            resources: [
                .process("../../Resources/Localizable.xcstrings")
            ]
        ),
        .testTarget(
            name: "PluginToastTests",
            dependencies: [
                "PluginToast",
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "ProviderToast", package: "ProviderToast"),
            ],
            path: "Tests/PluginToastTests"
        ),
    ]
)
