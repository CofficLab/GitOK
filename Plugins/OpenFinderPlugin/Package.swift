// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OpenFinderPlugin",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "OpenFinderPlugin",
            targets: ["OpenFinderPlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
        .package(path: "../../Packages/GitOKSupportKit"),
    ],
    targets: [
        .target(
            name: "OpenFinderPlugin",
            dependencies: [
                "GitOKCoreKit",
                .product(name: "GitOKDesignKit", package: "GitOKSupportKit"),
            ],
            path: "Sources",
            resources: [
                .process("Localizable.xcstrings"),
            ]
        ),
        .testTarget(
            name: "OpenFinderPluginTests",
            dependencies: ["OpenFinderPlugin"],
            path: "Tests"
        ),
    ]
)
