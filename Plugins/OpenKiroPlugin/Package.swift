// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OpenKiroPlugin",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "OpenKiroPlugin", targets: ["OpenKiroPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
        .package(path: "../../Packages/GitOKSupportKit"),
    ],
    targets: [
        .target(
            name: "OpenKiroPlugin",
            dependencies: [
                "GitOKCoreKit",
                .product(name: "GitOKDesignKit", package: "GitOKSupportKit"),
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "OpenKiroPluginTests",
            dependencies: ["OpenKiroPlugin"],
            path: "Tests"
        ),
    ]
)
