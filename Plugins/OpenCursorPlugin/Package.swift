// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OpenCursorPlugin",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "OpenCursorPlugin",
            targets: ["OpenCursorPlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
        .package(path: "../../Packages/GitOKSupportKit"),
    ],
    targets: [
        .target(
            name: "OpenCursorPlugin",
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
            name: "OpenCursorPluginTests",
            dependencies: ["OpenCursorPlugin"],
            path: "Tests"
        ),
    ]
)
