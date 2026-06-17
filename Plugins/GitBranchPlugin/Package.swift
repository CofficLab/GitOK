// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GitBranchPlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "GitBranchPlugin", targets: ["GitBranchPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitCoreKit"),
        .package(path: "../../Packages/GitOKCoreKit"),
        .package(path: "../../Packages/GitOKAppCore"),
        .package(path: "../../Packages/ProjectRulesKit"),
    ],
    targets: [
        .target(
            name: "GitBranchPlugin",
            dependencies: [
                "GitCoreKit",
                "GitOKCoreKit",
                "ProjectRulesKit",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "GitBranchPluginTests",
            dependencies: [
                "GitBranchPlugin",
                "GitOKAppCore",
            ],
            path: "Tests"
        ),
    ]
)
