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
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.2.1"),
        .package(path: "../ProviderConversation"),
        .package(path: "../KitLocalization"),
    ],
    targets: [
        .target(
            name: "ProviderChatSection",
            dependencies: [
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderConversation", package: "ProviderConversation"),
                .product(name: "KitLocalization", package: "KitLocalization"),
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
