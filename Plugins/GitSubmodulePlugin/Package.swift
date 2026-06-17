// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GitSubmodulePlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "GitSubmodulePlugin", targets: ["GitSubmodulePlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitCoreKit"),
        .package(path: "../../Packages/GitOKCoreKit"),
    ],
    targets: [
        .target(
            name: "GitSubmodulePlugin",
            dependencies: [
                "GitCoreKit",
                "GitOKCoreKit",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "GitSubmodulePluginTests",
            dependencies: [
                "GitCoreKit",
                "GitSubmodulePlugin",
            ],
            path: "Tests"
        ),
    ]
)
