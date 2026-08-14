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
        .library(name: "GitOKSupportKit", targets: ["GitOKSupportKit"]),
    ],
    dependencies: [
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
            path: "Sources/GitOKDesignKit"
        ),
        .target(
            name: "GitOKSupportKit",
            dependencies: [
                "GitOKFoundationKit",
                "GitOKDesignKit",
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
