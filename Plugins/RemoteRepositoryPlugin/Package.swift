// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RemoteRepositoryPlugin",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "RemoteRepositoryPlugin", targets: ["RemoteRepositoryPlugin"]),
    ],
    dependencies: [
        .package(path: "../../Packages/GitCoreKit"),
        .package(path: "../../Packages/GitOKCoreKit"),
        .package(path: "../../Packages/ProjectRulesKit"),
    ],
    targets: [
        .target(
            name: "RemoteRepositoryPlugin",
            dependencies: [
                "GitCoreKit",
                "GitOKCoreKit",
                "ProjectRulesKit",
            ],
            path: "Sources",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "RemoteRepositoryPluginTests",
            dependencies: ["RemoteRepositoryPlugin"],
            path: "Tests"
        ),
    ]
)
