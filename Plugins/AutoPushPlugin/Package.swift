// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AutoPushPlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "AutoPushPlugin", targets: ["AutoPushPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitCoreKit"),
        .package(path: "../../Packages/GitOKCoreKit"),
        .package(path: "../../Packages/ProjectRulesKit"),
        .package(path: "../../Packages/ProjectSupportKit"),
    ],
    targets: [
        .target(
            name: "AutoPushPlugin",
            dependencies: [
                "GitCoreKit",
                "GitOKCoreKit",
                "ProjectRulesKit",
                "ProjectSupportKit",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "AutoPushPluginTests",
            dependencies: ["AutoPushPlugin"],
            path: "Tests"
        ),
    ]
)
