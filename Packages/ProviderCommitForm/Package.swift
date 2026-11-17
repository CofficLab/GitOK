// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProviderCommitForm",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "ProviderCommitForm",
            targets: ["ProviderCommitForm"]
        ),
    ],
    dependencies: [
        .package(path: "../KitGitOKLocalization"),
        .package(url: "https://github.com/CofficLab/LumiProviders.git", from: "1.22.0"),
        .package(path: "../KitGit"),
        .package(path: "../ProviderGit"),
        .package(path: "../ProviderCoAuthor"),
    ],
    targets: [
        .target(
            name: "ProviderCommitForm",
            dependencies: [
                .product(name: "KitGitOKLocalization", package: "KitGitOKLocalization"),
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "ProviderGit", package: "ProviderGit"),
                .product(name: "ProviderCoAuthor", package: "ProviderCoAuthor"),
                .product(name: "ProviderStorage", package: "LumiProviders"),
            ],
            path: "Sources/ProviderCommitForm",
            resources: [
                .process("../../Resources/Localizable.xcstrings")
            ]
        ),
        .testTarget(
            name: "ProviderCommitFormTests",
            dependencies: [
                "ProviderCommitForm",
                .product(name: "KitGit", package: "KitGit"),
                .product(name: "ProviderGit", package: "ProviderGit"),
                .product(name: "ProviderCoAuthor", package: "ProviderCoAuthor"),
                .product(name: "ProviderStorage", package: "LumiProviders"),
            ],
            path: "Tests/ProviderCommitFormTests"
        ),
    ]
)
