// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OpenVSCodePlugin",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "OpenVSCodePlugin",
            targets: ["OpenVSCodePlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
        .package(path: "../../Packages/GitOKSupportKit"),
    ],
    targets: [
        .target(
            name: "OpenVSCodePlugin",
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
            name: "OpenVSCodePluginTests",
            dependencies: ["OpenVSCodePlugin"],
            path: "Tests"
        ),
    ]
)
