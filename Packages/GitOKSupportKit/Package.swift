// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GitOKSupportKit",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(name: "GitOKFoundationKit", targets: ["GitOKFoundationKit"]),
        .library(name: "GitOKDesignKit", targets: ["GitOKDesignKit"]),
        .library(name: "GitOKMediaKit", targets: ["GitOKMediaKit"]),
        .library(name: "GitOKShellKit", targets: ["GitOKShellKit"]),
        .library(name: "GitOKSupportKit", targets: ["GitOKSupportKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/chicio/ID3TagEditor", from: "4.5.0"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.19"),
        .package(path: "../MagicAlert"),
    ],
    targets: [
        .target(
            name: "GitOKFoundationKit",
            dependencies: [
                .product(name: "MagicAlert", package: "MagicAlert"),
            ],
            path: "Sources/GitOKFoundationKit",
            resources: [.process("Localizable.xcstrings")]
        ),
        .target(
            name: "GitOKDesignKit",
            dependencies: [
                "GitOKFoundationKit",
            ],
            path: "Sources/GitOKDesignKit",
            resources: [.process("Icons.xcassets")]
        ),
        .target(
            name: "GitOKMediaKit",
            dependencies: [
                "GitOKFoundationKit",
                "GitOKDesignKit",
                "ID3TagEditor",
                "ZIPFoundation",
            ],
            path: "Sources/GitOKMediaKit"
        ),
        .target(
            name: "GitOKShellKit",
            dependencies: [
                "GitOKFoundationKit",
            ],
            path: "Sources/GitOKShellKit"
        ),
        .target(
            name: "GitOKSupportKit",
            dependencies: [
                "GitOKFoundationKit",
                "GitOKDesignKit",
                "GitOKMediaKit",
                "GitOKShellKit",
            ],
            path: "Sources/GitOKSupportKit"
        ),
        .testTarget(
            name: "GitOKSupportKitTests",
            dependencies: ["GitOKSupportKit"],
            path: "Tests"
        ),
    ]
)
