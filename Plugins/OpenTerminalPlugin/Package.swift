// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OpenTerminalPlugin",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "OpenTerminalPlugin",
            targets: ["OpenTerminalPlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
        .package(path: "../../Packages/GitOKSupportKit"),
    ],
    targets: [
        .target(
            name: "OpenTerminalPlugin",
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
            name: "OpenTerminalPluginTests",
            dependencies: ["OpenTerminalPlugin"],
            path: "Tests"
        ),
    ]
)
