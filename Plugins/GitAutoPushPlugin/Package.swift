// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GitAutoPushPlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "GitAutoPushPlugin", targets: ["GitAutoPushPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitCoreKit"),
        .package(path: "../../Packages/GitOKCoreKit"),
        .package(path: "../../Packages/ProjectRulesKit"),
        .package(path: "../../Packages/ProjectSupportKit"),
    ],
    targets: [
        .target(
            name: "GitAutoPushPlugin",
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
            name: "GitAutoPushPluginTests",
            dependencies: ["GitAutoPushPlugin"],
            path: "Tests"
        ),
    ]
)
