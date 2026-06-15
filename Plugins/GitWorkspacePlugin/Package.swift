// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GitWorkspacePlugin",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "GitWorkspacePlugin",
            targets: ["GitWorkspacePlugin"]
        ),
    ],
    dependencies: [
        .package(path: "../../Packages/GitOKCoreKit"),
        .package(path: "../../Packages/GitOKUI"),
        .package(path: "../../Packages/ProjectRulesKit"),
        .package(path: "../../Packages/ProjectSupportKit"),
        .package(path: "../../Packages/GitCoreKit"),
        .package(path: "../../Packages/GitOKSupportKit"),
        .package(url: "https://github.com/nookery/MagicDiffView", branch: "main"),
    ],
    targets: [
        .target(
            name: "GitWorkspacePlugin",
            dependencies: [
                "GitOKCoreKit",
                "GitOKUI",
                "ProjectRulesKit",
                "ProjectSupportKit",
                "GitCoreKit",
                "GitOKSupportKit",
                "MagicDiffView",
            ],
            path: "Sources/GitWorkspace",
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "GitWorkspaceCoreTests",
            dependencies: ["GitWorkspacePlugin"],
            path: "Tests"
        ),
    ]
)
