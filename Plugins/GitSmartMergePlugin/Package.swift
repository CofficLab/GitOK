// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GitSmartMergePlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "GitSmartMergePlugin", targets: ["GitSmartMergePlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitCoreKit"),
        .package(path: "../../Packages/GitOKCoreKit"),
        .package(path: "../../Packages/GitOKUI"),
    ],
    targets: [
        .target(
            name: "GitSmartMergePlugin",
            dependencies: [
                "GitCoreKit",
                "GitOKCoreKit",
                "GitOKUI",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "GitSmartMergePluginTests",
            dependencies: ["GitSmartMergePlugin"],
            path: "Tests"
        ),
    ]
)
