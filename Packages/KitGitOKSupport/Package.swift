// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KitGitOKSupport",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(name: "KitGitOKFoundation", targets: ["KitGitOKFoundation"]),
        .library(name: "KitGitOKDesign", targets: ["KitGitOKDesign"]),
        .library(name: "KitGitOKSupport", targets: ["KitGitOKSupport"]),
    ],
    dependencies: [
        .package(path: "../MagicAlert"),
    ],
    targets: [
        .target(
            name: "KitGitOKFoundation",
            dependencies: [
                .product(name: "MagicAlert", package: "MagicAlert"),
            ],
            path: "Sources/KitGitOKFoundation",
            resources: [.process("Localizable.xcstrings")]
        ),
        .target(
            name: "KitGitOKDesign",
            dependencies: [
                "KitGitOKFoundation",
            ],
            path: "Sources/KitGitOKDesign"
        ),
        .target(
            name: "KitGitOKSupport",
            dependencies: [
                "KitGitOKFoundation",
                "KitGitOKDesign",
            ],
            path: "Sources/KitGitOKSupport"
        ),
        .testTarget(
            name: "KitGitOKSupportTests",
            dependencies: ["KitGitOKSupport"],
            path: "Tests"
        ),
    ]
)
