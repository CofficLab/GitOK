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
        .package(path: "../../Packages/GitOKUI"),
    ],
    targets: [
        .target(
            name: "OpenAntigravityPlugin",
            dependencies: [
                "GitOKCoreKit",
                .product(name: "GitOKDesignKit", package: "GitOKSupportKit"),
                "GitOKUI",
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
