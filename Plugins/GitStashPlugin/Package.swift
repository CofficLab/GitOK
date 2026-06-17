// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GitStashPlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "GitStashPlugin", targets: ["GitStashPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitCoreKit"),
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "GitStashPlugin",
            dependencies: [
                "GitCoreKit",
                "GitOKCoreKit",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "GitStashPluginTests",
            dependencies: [
                "GitCoreKit",
                "GitStashPlugin",
            ],
            path: "Tests"
        ),
    ]
)
