// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProviderChatSection",
    defaultLocalization: "en",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "ProviderChatSection", targets: ["ProviderChatSection"]),
    ],
    dependencies: [
        .package(path: "../KitGitOKLocalization"),
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.13.1"),
        .package(path: "../ProviderConversation"),
    ],
    targets: [
        .target(
            name: "ProviderChatSection",
            dependencies: [
                .product(name: "KitGitOKLocalization", package: "KitGitOKLocalization"),
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderConversation", package: "ProviderConversation"),
            ],
            path: "Sources/ProviderChatSection",
            resources: [
                .process("../../Resources/Localizable.xcstrings")
            ]
        ),
        .testTarget(
            name: "ProviderChatSectionTests",
            dependencies: [
                "ProviderChatSection",
                .product(name: "ProviderConversation", package: "ProviderConversation"),
            ]
        )
    ]
)
