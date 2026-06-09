// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SmartMergePlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "SmartMergePlugin", targets: ["SmartMergePlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitCoreKit"),
        .package(path: "../../Packages/GitOKCoreKit"),
        .package(path: "../../Packages/GitOKUI"),
    ],
    targets: [
        .target(
            name: "SmartMergePlugin",
            dependencies: [
                "GitCoreKit",
                "GitOKCoreKit",
                "GitOKUI",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "SmartMergePluginTests",
            dependencies: ["SmartMergePlugin"],
            path: "Tests"
        ),
    ]
)
