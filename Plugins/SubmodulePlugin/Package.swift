// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SubmodulePlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "SubmodulePlugin", targets: ["SubmodulePlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitCoreKit"),
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "SubmodulePlugin",
            dependencies: [
                "GitCoreKit",
                "GitOKCoreKit",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "SubmodulePluginTests",
            dependencies: [
                "GitCoreKit",
                "SubmodulePlugin",
            ],
            path: "Tests"
        ),
    ]
)
