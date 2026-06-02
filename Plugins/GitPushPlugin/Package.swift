// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GitPushPlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "GitPushPlugin", targets: ["GitPushPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitCoreKit"),
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "GitPushPlugin",
            dependencies: [
                "GitCoreKit",
                "GitOKCoreKit",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "GitPushPluginTests",
            dependencies: ["GitPushPlugin"],
            path: "Tests"
        ),
    ]
)
