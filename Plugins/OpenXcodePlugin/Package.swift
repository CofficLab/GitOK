// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OpenXcodePlugin",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "OpenXcodePlugin",
            targets: ["OpenXcodePlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
        .package(path: "../../Packages/GitOKSupportKit"),
    ],
    targets: [
        .target(
            name: "OpenXcodePlugin",
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
            name: "OpenXcodePluginTests",
            dependencies: ["OpenXcodePlugin"],
            path: "Tests"
        ),
    ]
)
