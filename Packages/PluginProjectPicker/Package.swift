// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginProjectPicker",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PluginProjectPicker",
            targets: ["PluginProjectPicker"]
        ),
    ],
    dependencies: [
        .package(path: "../KernelCore"),
        .package(path: "../KitSuperLog"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", branch: "main"),
        .package(path: "../ProviderProjects"),
        .package(path: "../ProviderToolbar"),
    ],
    targets: [
        .target(
            name: "PluginProjectPicker",
            dependencies: [
                .product(name: "KernelCore", package: "KernelCore"),
                .product(name: "KitSuperLog", package: "KitSuperLog"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderProjects", package: "ProviderProjects"),
                .product(name: "ProviderToolbar", package: "ProviderToolbar"),
            ],
            path: "Sources/PluginProjectPicker"
        ),
        .testTarget(
            name: "PluginProjectPickerTests",
            dependencies: ["PluginProjectPicker"],
            path: "Tests/PluginProjectPickerTests"
        ),
    ]
)
