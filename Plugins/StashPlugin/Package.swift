// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "StashPlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "StashPlugin", targets: ["StashPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitCoreKit"),
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "StashPlugin",
            dependencies: [
                "GitCoreKit",
                "GitOKCoreKit",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "StashPluginTests",
            dependencies: [
                "GitCoreKit",
                "StashPlugin",
            ],
            path: "Tests"
        ),
    ]
)
