// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProviderRootView",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "GitOKProviderRootView",
            targets: ["GitOKProviderRootView"]
        ),
    ],
    dependencies: [
        .package(path: "../KitGitOKLocalization"),
        .package(url: "https://github.com/lumi-softworks/LumiUI.git", from: "1.19.3"),
        .package(url: "https://github.com/lumi-softworks/LumiLogging.git", from: "1.0.3"),
        .package(url: "https://github.com/lumi-softworks/LumiProviders.git", from: "1.27.0")
    ],
    targets: [
        .target(
            name: "GitOKProviderRootView",
            dependencies: [
                .product(name: "KitGitOKLocalization", package: "KitGitOKLocalization"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderChatSection", package: "LumiProviders"),
                .product(name: "ProviderRailView", package: "LumiProviders"),
                .product(name: "ProviderRootView", package: "LumiProviders"),
                .product(name: "LumiLoggingKit", package: "LumiLogging"),
            ],
            path: "Sources/ProviderRootView",
            resources: [.process("../../Resources/Localizable.xcstrings")]
        ),
        .testTarget(
            name: "ProviderRootViewTests",
            dependencies: [
                "GitOKProviderRootView",
                .product(name: "ProviderChatSection", package: "LumiProviders"),
                .product(name: "ProviderRailView", package: "LumiProviders"),
                .product(name: "ProviderRootView", package: "LumiProviders"),
            ]
        )
    ]
)
