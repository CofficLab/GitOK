// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GitRemoteRepositoryPlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "GitRemoteRepositoryPlugin", targets: ["GitRemoteRepositoryPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitCoreKit"),
        .package(path: "../../Packages/GitOKCoreKit"),
        .package(path: "../../Packages/ProjectRulesKit"),
    ],
    targets: [
        .target(
            name: "GitRemoteRepositoryPlugin",
            dependencies: [
                "GitCoreKit",
                "GitOKCoreKit",
                "ProjectRulesKit",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "GitRemoteRepositoryPluginTests",
            dependencies: ["GitRemoteRepositoryPlugin"],
            path: "Tests"
        ),
    ]
)
