// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OpenRemotePlugin",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "OpenRemotePlugin", targets: ["OpenRemotePlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
        .package(path: "../../Packages/ProjectRulesKit"),
    ],
    targets: [
        .target(
            name: "OpenRemotePlugin",
            dependencies: [
                "GitOKCoreKit",
                "ProjectRulesKit",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "OpenRemotePluginTests",
            dependencies: ["OpenRemotePlugin"],
            path: "Tests"
        ),
    ]
)
