// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OpenAntigravityPlugin",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "OpenAntigravityPlugin", targets: ["OpenAntigravityPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
        .package(path: "../../Packages/GitOKSupportKit"),
    ],
    targets: [
        .target(
            name: "OpenAntigravityPlugin",
            dependencies: [
                "GitOKCoreKit",
                .product(name: "GitOKDesignKit", package: "GitOKSupportKit"),
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "OpenAntigravityPluginTests",
            dependencies: ["OpenAntigravityPlugin"],
            path: "Tests"
        ),
    ]
)
